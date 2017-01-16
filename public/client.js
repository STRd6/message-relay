// client-side js
// run by the browser each time your view template is loaded

// by default, you've got jQuery,
// add other scripts at the bottom of index.html

$(function() {
  var socket;
  console.log('hello world :o');

  function createWebSocket(path) {
    var protocolPrefix = (window.location.protocol === 'https:') ? 'wss:' : 'ws:';
    return new WebSocket(protocolPrefix + '//' + location.host + path);
  }
  
  var displayMessage = function(messageJSON) {
    log.innerText += messageJSON + "\n";
  };

  setInterval(function(){
    if(socket) {
      message = {
        type: "meta",
        keepalive: true
      };
      messageJSON = JSON.stringify(message);
      socket.send(messageJSON);
      displayMessage(messageJSON);
    }
  }, 30000);

  $('form').submit(function(e) {
    e.preventDefault();

    if(socket) {
      socket.close();
    }
    socket = createWebSocket('/r/yolo?accountId=anon' + (0 | Math.random() * 10000) );

    socket.onopen = function() {
      console.log('open');
      socket.send(JSON.stringify({
        type: "broadcast",
        message: "hello"
      }));
    };

    socket.onclose = function() {
      if(socket.closed) {
        socket = null;
      }

      displayMessage(JSON.stringify({
        type: "local",
        status: "close"
      }));
    };

    socket.onmessage = function(e) {
      message = JSON.parse(e.data);
      console.log("message", message);
      displayMessage(e.data);
    };
  });

});
