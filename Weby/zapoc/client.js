//Connecting buttons events.
window.onload = function() {
    var deleteBtns = document.getElementsByClassName("dltBtn");
    for(var i = 0; i < deleteBtns.length; ++i) {
        deleteBtns[i].addEventListener('click', deleteBtnOnClick, false);
    }

    var editbtns = document.getElementsByClassName('editBtn')
    for(var i = 0; i < editbtns.length; ++i) {
        editbtns[i].addEventListener('click', editBtnOnClick, false);
    }

    var swapbtns = document.getElementsByClassName('swapBtn');
    for(var i = 0; i < swapbtns.length; ++i) {
        swapbtns[i].addEventListener('click', swapBtnOnClick, false);
    }

    var dangerCloseBtns = document.getElementsByClassName('closebtn');
    for(var i = 0; i < dangerCloseBtns.length; ++i) {
        dangerCloseBtns[i].addEventListener('click', dangerCloseBtnOnClick, false);
    }
}

//Request to delete an item from the shopping list.
function deleteBtnOnClick() {
    var id = this.getAttribute('data-id');
    httpRequest = new XMLHttpRequest()
    httpRequest.open('POST', 'delete_item.php', true);
    httpRequest.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
    httpRequest.posted = id;
    httpRequest.h = false;
    httpRequest.onreadystatechange = function () {
        if(httpRequest.status === 200) {
            var row = document.getElementById('row-' + this.posted);
            if(row !== null) {
                if(row.nextElementSibling === null && row.previousElementSibling !== null) {
                    var pr = row.previousElementSibling;
                    pr.children[2].removeChild(pr.children[2].children[0]);
                }
                row.remove();
            }
        }
        else {
            if(this.h === false) {
                alert("Delete failed, try again.");
                this.h = true;
            }
        }
    }
    httpRequest.send('del_item_id=' + id);
}

/*
Converts String to Node.
@param html: string representation of an Node.
@returns: Node representation of an Node.
*/
function htmlToElement(html) {
    var template = document.createElement('template');
    html = html.trim(); 
    template.innerHTML = html;
    return template.content.firstChild;
}


/*
Request to edit the amount of an item on the shopping list.
Displays simple form.
*/
function editBtnOnClick() {
    var id = this.getAttribute('data-id');
    var label = htmlToElement("<span>Amount: </span>");
    var amount = htmlToElement('<input type="number" required min="1" id="amount-' + id + '">'); 
    var ok = htmlToElement('<button class="btn okBtn" data-id="' + id + '">Ok</button>');
    var cancel = htmlToElement('<button id="cnc-'+id+'" class="btn dltBtn" data-id="' + id + '">Cancel</button>');

    var parenttr = document.getElementById('row-' + id);
    if(parenttr.cells.length === 5) {

        var curAmount = document.getElementById('act-' + id).innerText;
        amount.value = curAmount;
        cancel.addEventListener('click', cancelBtnOnClick, false);
        ok.addEventListener('click', okBtnOnClick, false);
        var form = htmlToElement('<td class="ed" id="edit-'+ id +'"></td>')
        form.appendChild(label);
        form.appendChild(amount);
        form.appendChild(ok);
        form.appendChild(cancel);
        parenttr.appendChild(form);
    }
}

/*
Request to cancel the edit of the amount of an item on the shopping list.
Removes the amount editation form from the page.
*/
function cancelBtnOnClick() {
   var id = this.getAttribute('data-id');
   var editTd = document.getElementById('edit-' + id);
   if(editTd !== null) {
       editTd.remove();
   }
}

/*
Request to POST the new amount of an item
Uses AJAX
*/
function okBtnOnClick() {
    var id = this.getAttribute('data-id');
    var amountEl = document.getElementById('amount-' + id);
    var el = document.getElementById('act-' + id);
    if(el !== null) {
        var oldVal = document.getElementById('act-' + id).innerText;
    }
    if(amountEl !== null && amountEl.checkValidity() && oldVal !== amountEl.value) {
        httpRequest = new XMLHttpRequest()
        httpRequest.open('POST', 'edit_amount.php', true);
        httpRequest.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
        httpRequest.id = id;
        httpRequest.newamount = amountEl.value;
        httpRequest.h = false;
        httpRequest.onreadystatechange = function () {
            if(httpRequest.status === 200) {
                var elChange = document.getElementById('act-' + this.id);
                elChange.innerHTML = this.newamount;
                var c = document.getElementById('cnc-' + this.id);
                if(c !== null) {
                    c.click();
                }
            }
            else {
                if(this.h === false) {
                    this.h = true;
                    alert('Edit failed, try again.')
                }
            }
        }
        httpRequest.send('item_id=' + id + '&new_amount=' + amountEl.value);
    }
    else if (amountEl !== null && oldVal === amountEl.value) {
        document.getElementById('cnc-'+ id).click();
    }
    else {
        alert('Edit failed, try again.')
    }
}

/*
Given row name, returns the id part.
@param row: Name of an row.
@returns: Id part of an row.

Ex: Let row = 'row-12', the function returns 12.
*/
function extractId(row) {
    return row.split('-')[1];
}

/*
Swap button clicked.
Sends the new order of items to the server using AJAX.
After sucessful processing by the server, reorders the items to reflect the change.
*/
function swapBtnOnClick() {
    var prevId = this.getAttribute('data-prev');
    var nextId = this.getAttribute('data-next');
    httpRequest = new XMLHttpRequest()
    httpRequest.open('POST', 'change_order.php', true);
    httpRequest.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
    httpRequest.previd = prevId;
    httpRequest.nextid = nextId;
    httpRequest.swaped = false;
    httpRequest.h = false;
    httpRequest.onreadystatechange = function () {
        if(httpRequest.status === 200) {
            if(!this.swaped) {
                this.swaped = true;
                var rowP = document.getElementById('row-' + this.previd);
                var rowN = document.getElementById('row-' + this.nextid);
                if(rowP !== null && rowN !== null) {
                    rowP.before(rowN);

                if(rowP.nextElementSibling === null) {
                    var c = rowP.children[2];
                    rowP.replaceChild(htmlToElement('<td></td>'), rowP.children[2]);
                    rowN.replaceChild(c, rowN.children[2]);
                    cc = c.children[0];
                    var pr = cc.getAttribute('data-prev');
                    var ne = cc.getAttribute('data-next');
                    cc.setAttribute('data-prev', ne);
                    cc.setAttribute('data-next', pr);
                    cc.id = 'swp-' + ne +'-' + pr
                }

                 if(rowN.children[2].children.length == 1 && rowP.nextElementSibling !== null) {
                        var b = rowN.children[2].children[0];
                        var id = rowP.children[2].children[0].getAttribute('data-prev');
                        b.setAttribute('data-next', id);
                        b.id = 'swp-' + b.getAttribute('data-prev') + '-' + this.previd;
                    }
                    }
                    if(rowP.children[2].children.length == 1) {
                        var b = rowP.children[2].children[0];
                        var r = rowP.nextElementSibling;
                        if(r !== null) {
                        var id = extractId(r.id);
                        b.setAttribute('data-next', id);
                        b.id = 'swp-' + b.getAttribute('data-prev') + '-' + id;
                        }
                    }

                    if(rowN.previousElementSibling !== null) {
                        var rowF = rowN.previousElementSibling;
                        var b = rowF.children[2].children[0];
                        b.setAttribute('data-next', this.nextid);
                        b.id = 'swp-' + b.getAttribute('data-prev') + '-' + this.nextid;
                    }
        }
        }
        else {
            if(this.h === false) {
                this.h = true;
                alert('Swapping failed, try again.');
            }
        }
    }
    httpRequest.send('prev_id=' + prevId + '&next_id=' + nextId);
}

//Request to close an error message box.
function dangerCloseBtnOnClick() {
    this.parentElement.style.display = 'none';
}
