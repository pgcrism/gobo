indexing
   description:	"A tree based XML Parser"
   status:			"See notice at end of class."
   author:			"Andreas Leitner"
   note:				"Although it is not DOM (Level 1) conforming, it has %
   %been writen with DOM in mind. I prefer to have this %
   %parser follow the Eiffel design guide lines";
deferred class
   XI_TREE_PARSER

inherit
   XI_PARSER
   
feature {ANY} -- Access
   
   document: XM_DOCUMENT is
	 -- The document that has been generated by the parser.
      deferred
      end
   
   is_position_table_enabled: BOOLEAN is
	 -- if True, while parsing a position table will be build and 
	 -- made available via `last_position_table'. Default is False.
      deferred
      end
   
   last_position_table: XM_POSITION_TABLE is
      deferred
      end

feature {ANY} -- Basic Opertations   
   
   enable_position_table is
      deferred
      end
   
   disable_position_table is
      deferred
      end
   
   
   
end -- class XI_TREE_PARSER
--|-------------------------------------------------------------------------
--| eXML, Eiffel XML Parser Toolkit
--| Copyright (C) 1999  Andreas Leitner and others
--| See the file forum.txt included in this package for licensing info.
--|
--| Comments, Questions, Additions to this library? please contact:
--|
--| Andreas Leitner
--| Arndtgasse 1/3/5
--| 8010 Graz
--| Austria
--| email: andreas.leitner@chello.at
--| www: http://exml.dhs.org
--|-------------------------------------------------------------------------
