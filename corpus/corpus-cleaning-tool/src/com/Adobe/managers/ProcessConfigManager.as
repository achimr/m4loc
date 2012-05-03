//////////////////////////////////////////////////////////////////////////////////////
//
//    Copyright 2012 Adobe Systems Incorporated
//
//    This file is part of TMX to Moses Corpus Tool.
// 
//    TMX to Moses Corpus Tool is free software: you can redistribute it and/or modify
//    it under the terms of the GNU Lesser General Public License as published by the 
//    Free Software Foundation, either version 3 of the License, or (at your option) 
//    any later version.
// 
//    TMX to Moses Corpus Tool is distributed in the hope that it will be useful,
//    but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY 
//    or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for 
//    more details.
// 
//    You should have received a copy of the GNU Lesser General Public License along 
//    with TMX to Moses Corpus Tool.  If not, see <http://www.gnu.org/licenses/>.
//
//////////////////////////////////////////////////////////////////////////////////////


package com.Adobe.managers
{
	import com.Adobe.config.UserConfig;
	
	import flash.filesystem.*;
	import flash.filesystem.FileStream;

	public class ProcessConfigManager
	{
		private static var _instance:ProcessConfigManager;
		
		private var _configPath:File = new File(File.applicationStorageDirectory.nativePath);
		
		private var _defaultConfigPath:File = new File(File.applicationDirectory.nativePath);
		private var _defaultConfigFile:File = _defaultConfigPath.resolvePath("assets/DefaultProcess.xml");
		
		private var _usrConfig:UserConfig = UserConfig.getInstance();
		
		private var _defaultProcess:XML = new XML();
		
		public function ProcessConfigManager()
		{
			if(_instance != null)
			{
				throw new Error("Singleton!");
			}
			
//			_defaultProcess = getDefaultProcess();
			
		}
		
		public static function getInstance():ProcessConfigManager
		{
			if (_instance == null)
			{
				_instance = new ProcessConfigManager();
			}
			
			return _instance;
		}
		
//		public function get defaultProcess():XML
//		{
//			return _defaultProcess;
//		}
		
		public function saveDefaultProcess(targetLang:String, force:Boolean = false):void
		{
			var configFile:File = _configPath.resolvePath(_usrConfig.coreLanguage.replace(/-/,"_") + "-" + targetLang.replace(/-/,"_") + ".xml");
			
			if ( !configFile.exists || force )
			{
				var fs:FileStream = new FileStream();
				
				var newXML:XML = getDefaultProcess();
				
				newXML.@src = _usrConfig.coreLanguage;
				newXML.@target = targetLang;
				
				fs.open(configFile, FileMode.WRITE);
				
				fs.writeUTFBytes(newXML);
				
				fs.close();
			}
			
		}
		
		public function swapStepsAt(targetLang:String, firstOrder:int, secondOrder:int):void
		{
			var configFile:File = _configPath.resolvePath(_usrConfig.coreLanguage.replace(/-/,"_") + "-" + targetLang.replace(/-/,"_") + ".xml");

			if ( configFile.exists )
			{
				var fs:FileStream = new FileStream();
				
				fs.open(configFile, FileMode.READ);
				
				var newXML:XML = XML(fs.readUTFBytes(fs.bytesAvailable));
				
				var child1:XML = newXML.children()[firstOrder - 1];
				var child2:XML = newXML.children()[secondOrder - 1];
				
				newXML.replace(firstOrder - 1, child2);
				newXML.replace(secondOrder - 1, child1);
				
				fs.open(configFile, FileMode.WRITE);
				
				fs.writeUTFBytes(newXML);
				
				fs.close();
			}
		}
		
		public function switchStepState(targetLang:String, id:uint, isRun:Boolean):void
		{
			var configFile:File = _configPath.resolvePath(_usrConfig.coreLanguage.replace(/-/,"_") + "-" + targetLang.replace(/-/,"_") + ".xml");
			
			if ( configFile.exists )
			{
				var fs:FileStream = new FileStream();
				
				fs.open(configFile, FileMode.READ);
				
				var newXML:XML = XML(fs.readUTFBytes(fs.bytesAvailable));
				
				if (isRun)
				{
					newXML.children()[id].@enable = "yes";
				}
				else
				{
					newXML.children()[id].@enable = "no";
				}
				
				fs.open(configFile, FileMode.WRITE);
				
				fs.writeUTFBytes(newXML);
				
				fs.close();
			}
		}
		
		public function changeStepParameters(targetLang:String, id:uint, para:Array):void
		{
			var configFile:File = _configPath.resolvePath(_usrConfig.coreLanguage.replace(/-/,"_") + "-" + targetLang.replace(/-/,"_") + ".xml");
			
			if ( configFile.exists )
			{
				var fs:FileStream = new FileStream();
				
				fs.open(configFile, FileMode.READ);
				
				var newXML:XML = XML(fs.readUTFBytes(fs.bytesAvailable));
				
				newXML.children()[id].children()[para[0]] = para[1];
				
				fs.open(configFile, FileMode.WRITE);
				
				fs.writeUTFBytes(newXML);
				
				fs.close();
			}
		}
		
		public function getProcess(targLang:String = ""):XML
		{
			var xml:XML = new XML();
			
			var configFile:File = _configPath.resolvePath(_usrConfig.coreLanguage.replace(/-/,"_") + "-" + targLang.replace(/-/,"_") + ".xml");
			
			if ( !configFile.exists || (targLang == "") )
			{
				xml = getDefaultProcess();
			}
			else
			{
				var fs:FileStream = new FileStream();
				fs.open(configFile, FileMode.READ);
				
				xml = XML(fs.readUTFBytes(fs.bytesAvailable));
				
				fs.close();
			}
			
			return xml;
		}

		private function getDefaultProcess():XML
		{
			var xml:XML = new XML();
			
			if (_defaultConfigFile.exists)
			{
				var fs:FileStream = new FileStream();
				fs.open(_defaultConfigFile, FileMode.READ);
				
				xml = XML(fs.readUTFBytes(fs.bytesAvailable));
				
				fs.close();
			}
			
			return xml;
		}
	}
}