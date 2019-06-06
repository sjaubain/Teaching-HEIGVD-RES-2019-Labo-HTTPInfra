$(function() {
	
	console.log("Loading matrix");

	function loadMatrix(){
		

		for(var nb = 0; nb < 20; ++nb) {
			
			$(".insert-text").text(nb);
		}

	};

	loadMatrix();
	setInterval(loadMatrix, 2000);
});