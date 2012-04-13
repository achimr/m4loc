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

require_once("./php/common.php");

function MosesCmdRun($script, $configFile)
{
	global $SUDO;
	global $BASH;
	global $LOG_FILE;
	global $OUTPUT;
	
// 	$LOG_FILE = $LOG_PATH . "moses_" . posix_getpid() . ".log";
	
// 	if (file_exists($LOG_FILE))
// 	{
// 		exit("$LOG_FILE is in use!\n"); 	
// 	}
// 
// 	$f = fopen($LOG_FILE, 'w') or die("can't open file");
// 	fclose($f);
	
// 	posix_mkfifo($LOG_FILE, 0600);
	
//	$script = getMosesScriptFullPath();
		
	//$cmd = sprintf("%s %s %s %s > /tmp/moseslog.txt &", $SUDO, $BASH, $script, $configFile);
	//passthru($cmd);
	$cmd = sprintf("%s %s %s 2>&1 > %s &", $BASH, $script, $configFile, $LOG_FILE);
	
	$p = popen("/usr/bin/sudo -s", 'w');
	fwrite($p, $cmd);
	pclose($p);
	
// 	$f = fopen($LOG_FILE, 'r');
// 	stream_set_blocking($f, false);
// 
// 	while (true)
// 	{
// 		 $readers = array($f);
// 		 $writers = NULL;
// 		 $excepts = NULL;
// 	 	 
// 		 if (stream_select($readers,$writers,$excepts,0,15) == 1)
// 		 {
//  			$line = stream_get_contents($f);
// 			$OUTPUT .= stream_get_contents($f);
// 			
// 			//echo $line;
// 			
// 			if (empty($line)) 
// 			{ 
//             	break; 
//             }
// 	 	 }
// 	}
// 	
// 	fclose($f);

}

?>
