indexing

	description:

		"'validate' commands for 'gexace'"

	system:     "Gobo Eiffel Xace"
	author:     "Andreas Leitner <nozone@sbox.tugraz.at>"
	copyright:  "Copyright (c) 2001, Andreas Leitner and others"
	license:    "Eiffel Forum Freeware License v1 (see forum.txt)"
	date:       "$Date$"
	revision:   "$Revision$"

class GEXACE_VALIDATE_COMMAND

inherit

	GEXACE_COMMAND

creation

	make

feature {NONE} -- Initialization

	make (a_variables: like variables; an_error_handler: like error_handler) is
			-- Create a new 'validate' command.
		require
			a_variables_not_void: a_variables /= Void
			an_error_handler_not_void: an_error_handler /= Void
		do
			variables := a_variables
			error_handler := an_error_handler
			xace_filename := default_system_filename
		ensure
			variables_set: variables = a_variables
			error_handler_set: error_handler = an_error_handler
			xace_filename_set: xace_filename = default_system_filename
		end

feature -- Execution

	execute is
			-- Execute 'validate' command.
		local
			a_parser: ET_XACE_PARSER
			a_file: like INPUT_STREAM_TYPE
		do
			!! a_parser.make_with_variables (variables, error_handler)
			a_file := INPUT_STREAM_.make_file_open_read (xace_filename)
			if INPUT_STREAM_.is_open_read (a_file) then
				a_parser.parse_file (a_file)
				INPUT_STREAM_.close (a_file)
			else
				error_handler.report_cannot_read_file_error (xace_filename)
			end
		end

end -- class GEXACE_VALIDATE_COMMAND
