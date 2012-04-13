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
	import com.Adobe.util.XMLUtility;
	import flash.filesystem.*;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import mx.collections.ArrayCollection;
	
	[Bindable]
	public class LanguageManager extends EventDispatcher
	{
//		public function LanguageManager(target:IEventDispatcher=null)
//		{
//			super(target);
//		}
		
		private static var _instance:LanguageManager;
		
		public function LanguageManager()
		{
			if(_instance != null){
				throw new Error("Singleton!");
			}
			
			getLanguages();
		}
		
		public static function getInstance():LanguageManager{
			if (_instance == null){
				_instance = new LanguageManager();
			}
			return _instance;
		}
		
		private var _allLanguages:XML = new XML();
		private var langFile:File = File.applicationDirectory.resolvePath("assets/Languages.xml");
//		private var _allLanguages:Array = new Array("en-US", "ja-JP", "fr-FR", "de-DE", "es-ES", "it-IT", "sv-SE", "nl-NL", "pt-BR", "da-DK", "fi-FI", "no-NO", "ko-KR", "zh-CN", "zh-TW", "iw-IL", "ar-AE", "hu-HU", "tr-TR", "cs-CZ", "pl-PL", "el-GR", "ru-RU");
//		private var _allLangCollection:ArrayCollection = new ArrayCollection();
		
		private var _selectedLanguage:Array = new Array();
//		private var _selLangCollection:ArrayCollection = new ArrayCollection();
		
//		public function set allLanguages(langList:Array):void
//		{
//			_allLanguages = langList;
//			dispatchEvent(new Event("allLanguagesChanged"));
//		}
//		
//		[Bindable(event="allLanguagesChanged")]
		public function get allLanguages():Array
		{
			var myXmlUtil:XMLUtility = new XMLUtility();
			
			return myXmlUtil.XMLList2Array(_allLanguages.children());
		}
		
		public function set selectedLanguages(langList:Array):void
		{
			_selectedLanguage = langList;
			dispatchEvent(new Event("selectedLanguagesChanged"));
		}
		
		[Bindable(event="selectedLanguagesChanged")]
		public function get selectedLanguages():Array
		{
			return _selectedLanguage;
		}
		
		private function getLanguages():void
		{
			var fs:FileStream = new FileStream();
			
			fs.open(langFile, FileMode.READ);
			_allLanguages = XML(fs.readUTFBytes(fs.bytesAvailable));
			fs.close();
		}
	}
}