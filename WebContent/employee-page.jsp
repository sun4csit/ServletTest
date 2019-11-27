<html>
<body>
<head>
<script
	src="https://ajax.googleapis.com/ajax/libs/jquery/3.3.1/jquery.min.js"></script>
<script>
	var lastActiveTime = new Date().getTime();
	var checkInterval = 30000; // in Milliseconds
	$(document).ready(function() {
		$('body').bind('click mousemove keypress scroll resize', function() {
			lastActiveTime = new Date().getTime();
			console.log("lastActiveTime : " + lastActiveTime);
		});
		setInterval(checkIdleTime, checkInterval); // call ajax every 30 sec
	});

	function checkIdleTime() {
		var diff = new Date().getTime() - lastActiveTime;
		if (diff > 20000) {//Redirection in 20 Secs of inactivity
			window.location.href = 'http://localhost:8080/Test/testServlet'
		} else {
			console.log("AJAX Call In Every " + checkInterval + " Millisecond");
			$.ajax({
				url : 'http://localhost:8080/Test/testServlet',
				error : function(data, status, xhr) {
					alert("cannot refresh session on server: " + xhr);
					window.location.reload();
				}
			});
		}
	}
</script>
</head>
<h2>Demo page</h2>
<br />
</body>
</html>