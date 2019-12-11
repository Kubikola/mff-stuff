<?php
require_once('db.php');

/**
 * Updates the amount of item with item_id = $item_d to $new_amount.
 *
 * @param int $item_id Id of an item to update.
 * @param int $new_amount New amount of that item.
 *
 * @return Bool Indicates whether the DB operation was successful.
 */
function update_amount(int $item_id, int $new_amount) : Bool {
    if($new_amount < 1) {
        throw new InvalidArgumentException('Invalid amount');
    }
    $stmt = $GLOBALS['_DBH']->prepare('update list set amount = :amnt where item_id = :itm;');
    $stmt->bindValue(':amnt', $new_amount, PDO::PARAM_INT);
    $stmt->bindValue(':itm', $item_id, PDO::PARAM_INT);
    $stmt->execute();
    return $stmt->rowCount() === 1;
}
if($_SERVER['REQUEST_METHOD'] == 'POST' and isset($_POST['item_id']) and isset($_POST['new_amount'])) {
    try {
        if(!update_amount($_POST['item_id'], $_POST['new_amount'])) {
            http_response_code(422); //Unprocessable Entity
        }
    }
    catch (Exception $e) {
        http_response_code(422); //Unprocessable Entity
        error_log('Attempt to update item\'s amount to non integer value.');
    }
}
?>