let scroll_buffer = []

const checkScrollSpeed = (function(settings){
    settings = settings || {};

    let lastPos, newPos, timer, delta,
        delay = 250; //settings.delay || 10;
    let start = new Date();

    function clear() {
        lastPos = null;
        delta = 0;
    }

    clear();

    return function(){
        newPos = window.scrollY;
        if ( lastPos != null ){ // && newPos < maxScroll
            delta = newPos -  lastPos;
        }
        lastPos = newPos;
        clearTimeout(timer);
        timer = setTimeout(clear, delay);
        return {start, delta};
    };
})();


document.addEventListener('scroll', function() {
    let measurement = checkScrollSpeed();
    console.log(measurement.toString());
    scroll_buffer.push(checkScrollSpeed());
    if (scroll_buffer.length > 100){
      //console.log(scroll_buffer);
      let message = {type: 'log_scroll', data: scroll_buffer};
      chrome.runtime.sendMessage(message);
      scroll_buffer = []
    }
});
