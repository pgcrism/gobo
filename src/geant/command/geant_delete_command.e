indexing

	description:

		"Delete commands"

	library:    "Gobo Eiffel Ant"
	author:     "Sven Ehrke <sven.ehrke@sven-ehrke.de>"
	copyright:  "Copyright (c) 2001, Sven Ehrke and others"
	license:    "Eiffel Forum Freeware License v1 (see forum.txt)"
	date:       "$Date$"
	revision:   "$Revision$"


class GEANT_DELETE_COMMAND

inherit

	GEANT_COMMAND
	KL_SHARED_FILE_SYSTEM

creation

	make

feature -- Status report

	is_file_executable: BOOLEAN is
			-- Can command be executed on a file?
		do
			Result := file /= Void and then file.count > 0
		ensure
			file_not_void: Result implies file /= Void
			file_not_empty: Result implies file.count > 0
		end

	is_directory_executable: BOOLEAN is
			-- Can command be executed on a directory?
		do
			Result := directory /= Void and then directory.count > 0
		ensure
			directory_not_void: Result implies directory /= Void
			directory_not_empty: Result implies directory.count > 0
		end

	is_executable: BOOLEAN is
			-- Can command be executed?
		do
			Result := is_file_executable xor is_directory_executable
		ensure then
			file_xor_directory: Result implies (is_file_executable xor is_directory_executable)
		end

feature -- Access

	directory: STRING
			-- Directory to delete

	file: STRING
			-- File to delete

feature -- Setting

	set_directory (a_directory: like directory) is
			-- Set `directory' to `a_directory'.
		require
			a_directory_not_void: a_directory /= Void
			a_directory_not_empty: a_directory.count > 0
		do
			directory := a_directory
		ensure
			directory_set: directory = a_directory
		end

	set_file (a_file: like file) is
			-- Set `file' to `a_file'.
		require
			a_file_not_void: a_file /= Void
			a_file_not_empty: a_file.count > 0
		do
			file := a_file
		ensure
			file_set: file = a_file
		end

feature -- Execution

	execute is
			-- Execute command.
		local
			a_directory: KL_DIRECTORY
		do
			if is_directory_executable then
				trace ("  [delete] " + directory + "%N")
				!! a_directory.make (directory)
				a_directory.recursive_delete
				if file_system.is_directory_readable (directory) then
					log ("  [delete] error: cannot delete directory '" + directory + "'%N")
					exit_code := 1
				end
			else
				check is_file_executable: is_file_executable end
				trace ("  [delete] " + file + "%N")
				file_system.delete_file (file)
				if file_system.is_file_readable (file) then
					log ("geant error: cannot delete file '" + file + "'%N")
					exit_code := 1
				end
			end
		end

end -- class GEANT_DELETE_COMMAND

