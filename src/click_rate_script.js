// Script records how long between pointer down and pointer up
// Then send message to background so that it can be logged in localstorage buffer

let click_len = 0;
let click_start = 0;

document.addEventListener('pointerdown', (event) => {
  click_start = new Date();
});

document.addEventListener('pointerup', (event) => {
  click_len = (new Date()) - click_start;
  // Send message to background to log click_len into localstorage buffer
  let message = {type: 'log_click', data: {click_start, click_len}};
  chrome.runtime.sendMessage(message);
  //alert(click_len);
  click_start = 0;
  click_len = 0;
});
