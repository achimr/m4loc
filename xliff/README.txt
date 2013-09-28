SCRIPT EXECUTION
================
1. Extract Moses InlineText from source document using Okapi Tikal or Rainbow
e.g. tikal.sh -xm file.xlf
2. Translate Moses InlineText with m4loc.pm
3. Leverage translated Moses InlineText back into source file using Okapi Tikal
   or Rainbow
e.g. tikal.sh -lm file.xlf

For the exact options for your use case please refer to the Okapi and M4Loc
integration tools reference documentation. The M4Loc integration tools
reference documentation also describes the individual process components.
Developers that want to learn how the components are used in the overall 
process should analyze the code in m4loc.pm.

All .pm files are so-called Perl modulinos that can be simultaneously used as
scripts or Perl modules.
