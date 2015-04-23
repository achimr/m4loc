## TMX To Moses Corpus Tool. ##



Launch the Corpus tool and the UI will offer you several options

### 1. Choose a .tmx file to process. ###

Browse to locate the .TMX file you want to prepare and filter for use as a training input for Moses or another MT training system.



Input your project name.  You can choose what ever name you'd like.  To ease workflow in the future you'll probably want to avoid using spaces in that name i.e. "_" (underscore) not "  " (simple whitespace)._

Select the languages you want to convert.  You have the option of selecting any other target language pairs present in the .tmx file to export.  If your .tmx if contains one target language select that one and you'll be able export Source and Target.  If your .tmx contains more then one target you can select both and your resulting export with contain Source and Target1 and Source and Target2.  There is no limit on how many language pairs you can export at one time from a multilingual .tmx file but time to complete export will go up as multiple languages are selected.

### 2.  Select your cleaning steps. ###





**Step 1. Clean Placeholder Tags.**  This option allows for the user to filter out a specific textual pattern from the selected Moses .tmx file.  This particular pattern is currently hard coded to remove place holder tags from .tmx files exported from World Server.

For example selecting this options and using it on this input string:
Input string: `<seg> blah blah blah <ph x="1">{1}</ph> blah blah blah </seg>`

Will result in the export of the following output string
Output string: ` <seg> blah blah blah {1} blah blah blah </seg> `

**Step 2. Clean URLs.** This option allows the user to filter URLs out of the Source and Target files.

**Step 3. Tokenize.**This option allows the user to toggle on or off Tokenization of the Source and Target files.  (Some configuration may be required to do certain languages.  For example an external Segmenter would be required to parse ZH\_CN.  This segmenter can be installed else where on the users system and will be integrated into the process using the "Config" button at UI.

**Step 4. Lowercase.**This option allows the user to convert both Source and Target to lowercase.  Toggling this option off will leave all text with it's original casing.

**Step 5. Clean Numbers.**  This option allows the user to remove entries from Source and Target where the Value of the Key,Value pair is composed entirely of numbers.

**Step 6. Clean Duplicate Lines.**   This option allows the user to remove duplicate lines from the Source and Target.  The default usage of this option will remove any lines where identical Source and Target have previously been seen in the file being processed.   There is an option available that allows you to keep Source and Target pairs which have identical Source but different Target Values.

**Step 7. Clean Long Sentences.**   This option allows the user to remove lines containing exceptionally long Source or Target entries.  User can determine how many tokens to choose as the cut off point beyond which entries will be filtered out.

**Step 8.  Clean "weird" aligned pairs.**  This option allows the user to remove entries (both Source and Target) where the proportional length of the Source and Target differ by a value chosen by the user.  The purpose of this option is in fact to remove corruptions from the .tmx file.  Corruption resulting from .tmx export can result in the random line break throwing off the correct ordering of Source and Target elements in the file.  One of the easiest ways to detect these automatically if by looking for radical differences in translation length between Source and Target.


### 3. Reorder and Reset Steps ###

**Reorder** The user may reorder any of the filtering steps using the hidden arrows on the right side of the UI.   Mouse over the area hidden to the left of each step and beneath the Reset Steps button and the arrows will become visible for use.  User may reorder any of the steps selected so that later options can be process before earlier ones, etc.

**Reset**  The user may reset all options back to their default settings and order using the reset button.

### 4. Configuration Options ###

The user can select additional configuration options in using the Config button in the lower left corner of the UI.


**Configuration UI**

**1. Export Location** The user may select the export path for their cleaned corpus.  Browse to and select a location.

**2. Language**   The user may select a different language as the Source language for the .tmx extraction.  The default setting in en\_US but with a multilingual .tmx any of the languages present could be designated as the Source.

**3. Extensions**  The user may select a path to a different segments and segmentation standard.  For the moment the extension addition defaults to selecting a required zh\_CN segmenter for parsing zh\_CN content.  In the future additional options will be provided here to access other segmenters and standards.

### 5. Convert & View Log ###


Convert After all desired configuration options and cleaning steps have been dialed in the User may press Convert kick off the conversion process.

View Log User may select view log to look at results of the filtering process.