// Script records how long between pointer down and pointer up (release)
// Then sends this info/message to background so that it can be logged in localstorage buffer
// And later sent to the database
let click_buffer = [];
let click_len = 0;
let click_start = 0;

document.addEventListener('pointerdown', (event) => {
  //console.log("Mouse down");
  click_start = new Date();
});

document.addEventListener('pointerup', (event) => {
  //console.log("Mouse up");
  click_len = (new Date()) - click_start;
  // Send message to background to log click_len into localstorage buffer
  let message = {type: 'log_clicks', data: {click_start, click_len}};
  /*
  if (click_buffer.length > 10) {
    chrome.runtime.sendMessage(click_buffer);
    click_buffer = [];
  }
  */
  chrome.runtime.sendMessage(message);
  //alert(click_len);
  click_start = 0;
  click_len = 0;
});
