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

require_once("./php/global_variables.php");

$config = "";
$train_model_list = "";

function isEmptyString($C_char)
{
	if (!is_string($C_char)) {
		return true;
	}
	if (empty($C_char)) {
		return true;
	}
	if ($C_char=='') {
		return true;
	}
	return false;

} 

function _exec($cmd)
{
	$WshShell = new COM("WScript.Shell");
	$oExec = $WshShell->Run("$cmd",3,false);

	//echo $cmd;
	return $oExec == 0 ? true : false;
}

function saveConfig($configFile, $configArr)
{	
	global $config;

	array_walk($configArr, 'addConfigItem');
	
// 	echo $config;
	
	$file = fopen($configFile, "w+");
	fwrite($file, $config);
	fclose($file);
}

function addConfigItem($value, $key)
{
	global $config;
	$config .= sprintf("%s=%s\n",$key,$value);
}

function getTrainingConfigFullPath()
{
	global $LOG_PATH;
	global $TRAIN_CONFIG_NAME;
	
	return $LOG_PATH . $TRAIN_CONFIG_NAME;
}

function getTrainingScriptFullPath()
{
	global $TRAIN_SCRIPT_PATH;
	global $TRAIN_SCRIPT_NAME;
	
// 	echo "Training script: " . $TRAIN_SCRIPT_PATH . $TRAIN_SCRIPT_NAME . "\n";
	return $TRAIN_SCRIPT_PATH . $TRAIN_SCRIPT_NAME;
}

function getEvaluationConfigFullPath()
{
	global $LOG_PATH;
	global $EVAL_CONFIG_NAME;
	
	return $LOG_PATH . $EVAL_CONFIG_NAME;
}

function getEvaluationScriptFullPath()
{
	global $EVAL_SCRIPT_PATH;
	global $EVAL_SCRIPT_NAME;
	
// 	echo "Evaluation script: " . $EVAL_SCRIPT_PATH . $EVAL_SCRIPT_NAME . "\n";
	return $EVAL_SCRIPT_PATH . $EVAL_SCRIPT_NAME;
}

function getTrainingList($src, $tar)
{
	global $TRAIN_DATA_ROOT;
	global $train_model_list;
	
	$train_engine_path = $TRAIN_DATA_ROOT . strtoupper($src) . "-" . strtoupper($tar);
	
	if (file_exists($train_engine_path))
	{
		$files = scandir($train_engine_path);
		
		array_walk($files, 'addTraingEngineID');
	}

	return $train_model_list;
}

function addTraingEngineID($value, $key)
{
	global $train_model_list;
	
	if ( ($value == ".") || ($value == "..") || ($value == "latest"))
		return;
	
	$train_model_list .= sprintf("%s,",$value);
}

function getEvalResults($src, $tar)
{
	global $TRAIN_DATA_ROOT;
	
	$train_list = getTrainingList($src, $tar);
	
	$train_list = explode(",", $train_list);
	
	$results = "";
	
	if (sizeof($train_list) > 0)
	{
		array_pop($train_list);
		
		for ($i = 0; $i < sizeof($train_list); $i++)
		{
			$result_file = $TRAIN_DATA_ROOT . strtoupper($src) . "-" . strtoupper($tar) . "/" . $train_list[$i] . "/score.log";
			
			if (file_exists($result_file))
			{
				$results .= file_get_contents($result_file);
				$results .= "\n";
			}
			else
			{
				$results .= sprintf("\n%s hasn't been scored yet. \n\n",$train_list[$i]);
			}
		}
	}
	
	return $results;
}	

?>
