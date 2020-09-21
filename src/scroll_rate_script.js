const checkScrollSpeed = (function(settings){
    settings = settings || {};

    let lastPos, newPos, timer, delta,
        delay = settings.delay || 50;

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
        return delta;
    };
})();


document.addEventListener('scroll', function() {
    //scroll_time = new Date();
    //console.log(checkScrollSpeed());
    //console.log(scroll_diff);
    //let message = {type: 'log_scroll', data: {scroll_time, scroll_diff}};
    //console.log(message)
    //chrome.runtime.sendMessage(message, function(response) {
    //console.log("Response: ", response);
    //});
});
