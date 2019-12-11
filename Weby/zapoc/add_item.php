<?php
require_once('db.php');

//start the session
if (session_status() == PHP_SESSION_NONE) {
    session_start();
}

/**
 * Generates datalist for items autocompletion.
 *
 * @return String HTML datalist for items autocompletion.
 */
function generate_datalist() : String {
    $out = '<datalist id="items">';
    $data = $GLOBALS['_DBH']->query('select name from items;')->fetchAll();
    foreach($data as $row) {
        $out .= "<option value=\"${row['name']}\">";
    }
    $out .= '</datalist>';
    return $out;
}

/**
 * Form for adding items to shopping list.
 *
 * @return String HTML element containing form used for adding items to the shopping list.
 */
function generate_form() : String {
    $out = '<div class="form"><form action="add_item.php" method="post">' . 
                    'Item:' .
                    '<input list="items" name="item" placeholder="potatoes" required><br>' . 
                    'Amount:' .
                    '<input type="number" min="1" name="amount" placeholder="1"><br>' .
                    '<button class="btn okBtn" type="submit">Add</button>';
    $out .= generate_datalist();
    $out .= '</form></div>';
    return $out;
}

/**
 * Gets underlying Id of an item given its name.
 *
 * @param string $item The name of an item we want its Id.
 *
 * @return Int The Id of that item.
 */
function item2id(string $item) : ?Int {
    $stmt = $GLOBALS['_DBH']->prepare('select id from items where items.name = :itm;');
    $stmt->bindValue(':itm', htmlspecialchars($item), PDO::PARAM_STR);
    $stmt->execute();
    $result = $stmt->fetch(PDO::FETCH_ASSOC); 
    if(isset($result['id'])) {
        return $result['id'];
    }
    return null;
}

/**
 * Inserts new (currently unknown) item into DB.
 *
 * @param string $item Name of new item.
 *
 * @return Int Id of new inserted item.
 */
function insert_item(string $item) : Int {
    $stmt = $GLOBALS['_DBH']->prepare('insert into items (name) values (:itm);');
    $stmt->bindValue(':itm', htmlspecialchars($item), PDO::PARAM_STR);
    $stmt->execute();
    return $GLOBALS['_DBH']->lastInsertId();
}

/**
 * @return Int Last position of an item on the shopping list.
 *             If no item is present in DB, then 0.
 */
function last_position() : Int {
    $data = $GLOBALS['_DBH']->query('select max(position) from list;')->fetchAll();
    return $data[0]['max(position)'] === null ? 0 : $data[0]['max(position)'];
}

/**
 * Inserts known item onto the shopping list.
 *
 * @param int $id Id of item to insert.
 * @param int $amount Number of pieces to put on the shopping list.
 *
 * @return void
 */
function insert_into_cart(int $id, int $amount) {
    $last_pos = last_position();
    $stmt = $GLOBALS['_DBH']->prepare('insert into list (item_id, amount, position) values (:itm, :amnt, :pos);');
    $stmt->bindValue(':itm', $id, PDO::PARAM_INT);
    $stmt->bindValue(':amnt', $amount, PDO::PARAM_INT);
    $stmt->bindValue(':pos', $last_pos + 1, PDO::PARAM_INT);
    $stmt->execute();
}

/**
 * Updates the amount of an item on the shopping list.
 *
 * @param int $id Id of an item whose amount to update.
 * @param int $amount New amount to put.
 *
 * @return Bool Indicates whether the update DB operation was successful.
 */
function update_on_cart(int $id, int $amount) : Bool {
    $stmt = $GLOBALS['_DBH']->prepare('update list set amount = amount + :amnt where item_id = :itm;');
    $stmt->bindValue(':itm', $id, PDO::PARAM_INT);
    $stmt->bindValue(':amnt', $amount, PDO::PARAM_INT);
    $stmt->execute();
    return $stmt->rowCount() === 1;
}

/**
 * Validates given parameter.
 *
 * @param int $amount to validate
 *
 * @return void
 */
function validateAmount(int $amount) {
    if($amount < 1) {
        throw new InvalidArgumentException('Invalid amount');
    }
}

/**
 * Deletes an item given by Id from DB.
 *
 * @param int $id Id of an item to remove from DB.
 *
 * @return void
 */
function delete_item(int $id) {
    $stmt = $GLOBALS['_DBH']->prepare('delete from items where id = :v;');
    $stmt->bindValue(':v', $id, PDO::PARAM_INT);
    $stmt->execute();
}

/**
 * Saves an error message to the session that will be displayed to the client. 
 *
 * @param string $msg Error message that should be displayed to client.
 *
 * @return void
 */
function show_err_box(string $msg) {
    $_SESSION['err'] = $msg;
}

echo("<h3>Add Item</h3>");
echo(generate_form());

if ($_SERVER['REQUEST_METHOD'] === 'POST' and isset($_POST['item'])) {
    $id = item2id($_POST['item']);
    $amount = !isset($_POST['amount']) ? 1 : $_POST['amount'];
    if($id === null) { //add new item do db, add it to cart
       $id = insert_item($_POST['item']);
       try {
            validateAmount($amount);
            insert_into_cart($id, $amount);
       }
       catch(Exception $e) {
           delete_item($id);
           error_log('Attempt to insert an item with invalid amount.');
           show_err_box('Error: Item not added!');
       }
    }
    else { //add/update existing item on cart
        try {
            validateAmount($amount);
            if(!update_on_cart($id, $amount)) {
                insert_into_cart($id, $amount);
            }
        }
        catch(Exception $e) {
            delete_item($id);
            error_log('Attempt to insert an item with invalid amount.');
            show_err_box('Error: Item not added!');
        }
    }
header('Location: index.php');
exit();
}
?>