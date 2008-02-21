indexing

	description:

		"Checkers to see whether the interface of a class need to be checked again %
		%or not after some classes have been modified in the universe."

	library: "Gobo Eiffel Tools Library"
	copyright: "Copyright (c) 2007, Eric Bezault and others"
	license: "MIT License"
	date: "$Date$"
	revision: "$Revision$"

class ET_INTERFACE_STATUS_CHECKER

inherit

	ET_CLASS_PROCESSOR
		redefine
			make,
			process_class
		end

create

	make

feature {NONE} -- Initialization

	make (a_universe: like universe) is
			-- Create a new interface status checker for classes in `a_universe'.
		do
			precursor (a_universe)
			create class_type_checker.make (a_universe)
		end

feature -- Processing

	process_class (a_class: ET_CLASS) is
			-- Check whether the interface of `a_class' need to be checked
			-- again after some classes have been modified in the universe. Also
			-- check whether none of the classes appearing in the parent types
			-- or formal generic parameter constraints have been modified.
			-- If `has_interface_error' is True, it means that this class
			-- has not been checked yet. False means that it has already
			-- been checked. Parent classes will be checked recursively.
		local
			a_processor: like Current
		do
			if a_class = none_class then
				a_class.unset_flattening_error
			elseif current_class /= unknown_class then
					-- Internal error (recursive call)
					-- This internal error is not fatal.
				error_handler.report_giaaa_error
				create a_processor.make (universe)
				a_processor.process_class (a_class)
			elseif a_class /= unknown_class then
				internal_process_class (a_class)
			else
				set_fatal_error (a_class)
			end
		ensure then
			interface_checked: not a_class.interface_checked or else not a_class.has_interface_error
		end

feature -- Error handling

	set_fatal_error (a_class: ET_CLASS) is
			-- Report a fatal error to `a_class'.
		do
			a_class.reset_after_features_flattened
		ensure then
			interface_not_checked: not a_class.interface_checked
		end

feature {NONE} -- Processing

	internal_process_class (a_class: ET_CLASS) is
			-- Check whether the interface of `a_class' need to be checked
			-- again after some classes have been modified in the universe. Also
			-- check whether none of the classes appearing in the parent types
			-- or formal generic parameter constraints have been modified.
			-- If `has_interface_error' is True, it means that this class
			-- has not been checked yet. False means that it has already
			-- been checked. Parent classes will be checked recursively.
		require
			a_class_not_void: a_class /= Void
		local
			old_class: ET_CLASS
			i, nb: INTEGER
			l_reset_needed: BOOLEAN
			a_parents: ET_PARENT_LIST
			a_parent_class: ET_CLASS
		do
			old_class := current_class
			current_class := a_class
			if current_class.interface_checked and then current_class.has_interface_error then
					-- The class has been mark with an interface error to indicate that
					-- we need to check whether its interface need to be checked again
					-- or not. It might happen if other classes on which it depends have
					-- been modified or recursively made invalid. If its interface is still
					-- valid then the error flag will be cleared. Otherwise the class will
					-- be reset to the previous processing step.
				current_class.unset_interface_error
					-- Process parents first.
				a_parents := current_class.parents
				if a_parents = Void or else a_parents.is_empty then
					if current_class = universe.general_class then
						a_parents := Void
					elseif current_class = universe.any_class then
							-- ISE Eiffel has no GENERAL class anymore.
							-- Use ANY as class root now.
						a_parents := Void
					elseif current_class.is_dotnet and current_class /= universe.system_object_class then
						a_parents := universe.system_object_parents
					else
						a_parents := universe.any_parents
					end
				end
				if a_parents /= Void then
					nb := a_parents.count
					from i := 1 until i > nb loop
							-- This is a controlled recursive call to `internal_process_class'.
						a_parent_class := a_parents.parent (i).type.direct_base_class (universe)
						internal_process_class (a_parent_class)
						if not a_parent_class.interface_checked then
							l_reset_needed := True
						end
						i := i + 1
					end
				end
				if l_reset_needed then
					set_fatal_error (current_class)
				else
					if not current_class.is_dotnet then
							-- No need to check validity of .NET classes.
						check_formal_parameters_validity
						check_parents_validity
					end
				end
			end
			current_class := old_class
		ensure
			interface_checked: not a_class.interface_checked or else not a_class.has_interface_error
		end

feature {NONE} -- Formal parameters and parents validity

	check_formal_parameters_validity is
			-- Check whether none of the classes appearing in the
			-- formal generic parameter constraints of `current_class'
			-- have been modified.
		local
			i, nb: INTEGER
			l_parameters: ET_FORMAL_PARAMETER_LIST
			l_constraint: ET_TYPE
		do
			if current_class.interface_checked then
				l_parameters := current_class.formal_parameters
				if l_parameters /= Void then
					nb := l_parameters.count
					from i := 1 until i > nb loop
						l_constraint := l_parameters.formal_parameter (i).constraint
						if l_constraint /= Void then
								-- This check is probably too strong in many cases. What we
								-- really need to check is whether the creation clause of
								-- of the constraint if any is still valid. But that would
								-- be too long to check. We don't need such level of
								-- fine-grained checking here.
							class_type_checker.check_type_validity (l_constraint)
							if class_type_checker.has_fatal_error then
								set_fatal_error (current_class)
								i := nb + 1 -- Jump out of the loop.
							end
						end
						i := i + 1
					end
				end
			end
		end

	check_parents_validity is
			-- Check whether none of the classes appearing in the
			-- parent types of `current_class' have been modified.
		local
			l_parents: ET_PARENT_LIST
			i, nb: INTEGER
		do
			if current_class.interface_checked then
				l_parents := current_class.parents
				if l_parents /= Void then
					nb := l_parents.count
					from i := 1 until i > nb loop
							-- This check is probably too strong in many cases. What we
							-- really need to check is whether the type of the parent
							-- is valid as a creation type, in particular when some of
							-- the corresponding formal generic parameters have a constraint
							-- with a creation clause. But that would be too long to check.
							-- We don't need such level of fine-grained checking here.
						class_type_checker.check_type_validity (l_parents.parent (i).type)
						if class_type_checker.has_fatal_error then
							set_fatal_error (current_class)
							i := nb + 1 -- Jump out of the loop.
						end
						i := i + 1
					end
				end
			end
		end

	class_type_checker: ET_CLASS_TYPE_CHECKER3
			-- Class type checker

invariant

	class_type_checker_not_void: class_type_checker /= Void

end
