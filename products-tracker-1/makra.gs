/**
 * Refresh data in military1st.co.uk sheet and send alert.
 */
function refreshData() {
  var sht = SpreadsheetApp.getActiveSpreadsheet().getSheetByName("military1st.co.uk");
  var lastRow = sht.getLastRow();
  var rngInStock = sht.getRange(2, 4, lastRow-1, 1);
  
  var data = sht.getRange(2, 1, lastRow-1, 6).getValues()
  var productsInStock = [];
  var productsOutOfStock = [];
  
  var email = 'bartosz.pawel.sekiewicz@gmail.com';
  var subject = 'Product Tracker Alert!';
  var message = '';

  // check changes
  for (var i in data) {
    var row = data[i];
    
    if ((row[3] != row[4]) && i>0) {
      if (row[3] == true) {
        productsInStock.push(row[0]);
      } else if (row[3] == false) {
        productsOutOfStock.push(row[0]);
      }
    }
  }

  // prepare and send alert email
  message = message + 'Products in stock:\n\n'
  if (productsInStock.length > 0) {
    message = message + productsInStock.join('\n') + '\n\n'
  } else {
    message = message + 'no change.\n\n'
  }
  
  message = message + 'Products out of stock:\n\n'
  if (productsOutOfStock.length > 0) {
    message = message + productsOutOfStock.join('\n') + '\n\n'
  } else {
    message = message + 'no change.\n\n'
  }
  
  if (productsInStock.length > 0 || productsOutOfStock.length > 0) {
    MailApp.sendEmail(email, subject, message);
  }
  
  // copy from in_stock to in_stock_prev
  rngInStock.copyValuesToRange(sht, 5, 5, 2, lastRow);
}