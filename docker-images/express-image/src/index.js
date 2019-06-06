
var Chance = require('chance');
var chance = new Chance();

var express = require('express');
var app = express();

app.get('/', function(req, res){

	res.send(generateMatrix());

});

app.listen(3000, function(){
	console.log('Accepting HTTP requests on port 3000');
});

// Dynamic content (generate random boolean matrix of size 1 to 10)
function generateMatrix(){
	
	var size = chance.integer({
		min : 1,
		max : 10
	});
	
	var matrix = [];
	for(var line = 0; line < size; ++line){
		
		matrix[line] = new Array(size);
		
		for(var column = 0; column < size; ++column){
			matrix[line][column] = chance.integer({
				min : 0,
				max : 1
			});
		}
	}
	console.log(matrix);
	return matrix;
}