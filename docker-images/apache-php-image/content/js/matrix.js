$(function() {
	
	console.log("Loading matrix");

	function loadMatrix(){
		
		// Get the dynamic content in express image
		$.getJSON( "/api/matrix/", function(matrix){
			console.log(matrix);
			
			// Concatenate all lines of the matrix in a string
			var m = "Matrix = [";
			for(var i = 0; i < matrix.length; ++i){
				m += '[';
				for(var j = 0; j < matrix.length; ++j){
					m += matrix[i][j];
				}
				m += ']';
				if(i < matrix.length - 1)
					m += ", ";
			}
			
			// Place the string in the right tag
			m += ']';				
			$(".insert-text").text(m);
		});
	};

	loadMatrix();
	setInterval(loadMatrix, 2000);
});