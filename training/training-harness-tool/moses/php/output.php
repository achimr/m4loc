<?php

//////////////////////////////////////////////////////////////////////////////////////
//
//ÊÊÊ Copyright 2012 Adobe Systems Incorporated
//
//ÊÊÊ This file is part of TMX to Moses Corpus Tool.
//Ê
//ÊÊÊ TMX to Moses Corpus Tool is free software: you can redistribute it and/or modify
//ÊÊÊ it under the terms of the GNU Lesser General Public License as published by the 
//ÊÊÊ Free Software Foundation, either version 3 of the License, or (at your option) 
//ÊÊÊ any later version.
//Ê
//ÊÊÊ TMX to Moses Corpus Tool is distributed in the hope that it will be useful,
//ÊÊÊ but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY 
//ÊÊÊ or FITNESS FOR A PARTICULAR PURPOSE.Ê See the GNU General Public License for 
//ÊÊÊ more details.
//Ê
//ÊÊÊ You should have received a copy of the GNU Lesser General Public License along 
//ÊÊ Êwith TMX to Moses Corpus Tool.Ê If not, see <http://www.gnu.org/licenses/>.
//
//////////////////////////////////////////////////////////////////////////////////////

function getLog($LOG_FILE)
{
//	global $LOG_FILE;
	
	echo file_get_contents($LOG_FILE);

}

// function getLog($logFile)
// {
// 	
// 	$f = fopen($logFile, 'r');
// 	stream_set_blocking($f, false);
// 
// 	 $readers = array($f);
// 	 $writers = NULL;
// 	 $excepts = NULL;
// 	 print posix_getpid();
// 	 if (stream_select($readers,$writers,$excepts,0,15) == 1)
// 	 {
// 		$line = stream_get_contents($f);
// 		
// 		echo "I'm in the loop";
// 
// 		echo $line;
// 		
// // 		if (empty($line)) 
// // 		{ 
// // 			break; 
// // 		}
// 	 }
// 	
// 	fclose($f);
// }

?>
