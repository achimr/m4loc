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
	import com.Adobe.config.ProcessConfig;
	import com.Adobe.config.UserConfig;
	import com.Adobe.util.UserUtility;
	
	import flash.filesystem.*;

	public class UserConfigManager
	{
		private var _usrConfig:UserConfig = UserConfig.getInstance();
		private var _processConfig:ProcessConfig = ProcessConfig.getInstance();
		private var _langMgr:LanguageManager = LanguageManager.getInstance();
		
		private var _configPath:File = new File(File.applicationStorageDirectory.nativePath);
		private var _configFile:File = _configPath.resolvePath("UserConfig.xml");
		
		private var _configFileContent:XML;
		
		private static var _instance:UserConfigManager;
		
		public function UserConfigManager()
		{
			if(_instance != null){
				throw new Error("Singleton!");
			}
		}
		
		public static function getInstance():UserConfigManager
		{
			if (_instance == null){
				_instance = new UserConfigManager();
			}
			
			return _instance;
		}
		
		public function get configFile():File
		{
			return _configFile;
		}
		
		public function loadConfig():void
		{
			if (_configFile.exists)
			{
				var fs:FileStream = new FileStream();
				fs.open(_configFile, FileMode.READ);
				
				_configFileContent = XML(fs.readUTFBytes(fs.bytesAvailable));
				
				_usrConfig.coreLanguage = _configFileContent.language.src;
				_usrConfig.exportPath = _configFileContent.exportdir;
//				_usrConfig.mosesPath = _configFileContent.mosesPath;
				_usrConfig.chsSegmenterPath = _configFileContent.extensions.StanfordChineseWordSegmenter.Path;
				_usrConfig.chsSegmentationStandard = _configFileContent.extensions.StanfordChineseWordSegmenter.Standard;
				
				fs.close();
			}
		}
		
		public function updConfig():void
		{
			var fs:FileStream = new FileStream();
		
			if (_configFile.exists)
			{
				fs.open(_configFile, FileMode.READ);
				
				_configFileContent = XML(fs.readUTFBytes(fs.bytesAvailable));					
			}
			else
			{
				_configFileContent = new XML("<?xml version=\"1.0\" encoding=\"UTF-8\"?><config/>");
			}
							
			_configFileContent.exportdir = _usrConfig.exportPath;
			_configFileContent.language.src = _usrConfig.coreLanguage;
			_configFileContent.extensions.StanfordChineseWordSegmenter.Path = _usrConfig.chsSegmenterPath;
			_configFileContent.extensions.StanfordChineseWordSegmenter.Standard = _usrConfig.chsSegmentationStandard;
			
			fs.open(_configFile, FileMode.WRITE);
			fs.writeUTFBytes(_configFileContent);
			fs.close();			
		}
		
		public function saveConfig(rawFiles:Array):void
		{
			var fs:FileStream = new FileStream();
			var userUtil:UserUtility = new UserUtility();
			
			_configFileContent = new XML("<?xml version=\"1.0\" encoding=\"UTF-8\"?><config/>");
			
			_configFileContent.project = _processConfig.projectName;
			_configFileContent.exportdir = _usrConfig.exportPath;
			_configFileContent.extensions.StanfordChineseWordSegmenter.Path = _usrConfig.chsSegmenterPath;
			_configFileContent.extensions.StanfordChineseWordSegmenter.Standard = _usrConfig.chsSegmentationStandard;
			_configFileContent.user.name = userUtil.currentOSUser;
			_configFileContent.user.configpath = File.applicationStorageDirectory.nativePath;
			
			var fileList:XML = new XML("<rawfiles/>");
			
			fileList.@format = "tmx";
			
			for each (var file:File in rawFiles)
			{
				fileList.appendChild(XML("<file>" + file.nativePath + "</file>"));
			}
			
			_configFileContent.appendChild(fileList);
			
			var targLangList:XML = new XML("<targetlist/>");
			
			for each (var lang:String in _langMgr.selectedLanguages)
			{
				targLangList.appendChild(XML("<target>" + lang + "</target>"));
			}
			
			_configFileContent.language.src = _usrConfig.coreLanguage;
			_configFileContent.language.appendChild(targLangList);
//			_configFileContent.mosesPath = _usrConfig.mosesPath;
			
			fs.open(_configFile, FileMode.WRITE);
			fs.writeUTFBytes(_configFileContent);
			fs.close();
		}
	}
}