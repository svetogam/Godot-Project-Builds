extends GutTest

const PROJECTS := {
	1: "res://Tests/Projects/TestProject1/",
}
const ROUTINES := {
	# TestProject1
	"copy_files": 0,
	"clear_directory_files": 1,
	"pack_zip": 2,
	"sub_routine": 3,
	"cyclic_sub_routine_1": 7,
	"cyclic_sub_routine_2": 9,
	"bash_custom_task": 10,
	"windows_custom_task": 11,
}
const EXECUTION_TIMEOUT := 5.0
const Scene := preload("res://Scenes/Execution.tscn")
var scene: Node
var original_exec_delay

func before_all():
	original_exec_delay = Data.global_config["execution_delay"]
	Data.global_config["execution_delay"] = 0

func before_each():
	scene = Scene.instantiate()

func after_each():
	scene.free()

func after_all():
	Data.global_config["execution_delay"] = original_exec_delay

func test_copy_files():
	# Check assumptions
	assert_true(FileAccess.file_exists(PROJECTS[1] + "file1.txt"))
	assert_false(FileAccess.file_exists(PROJECTS[1] + "file1-copy.txt"))
	assert_false(FileAccess.file_exists(PROJECTS[1] + "EmptyDir/file1-copy.txt"))
	assert_true(DirAccess.dir_exists_absolute(PROJECTS[1] + "MessyDir"))
	assert_false(DirAccess.dir_exists_absolute(PROJECTS[1] + "EmptyDir/MessyDirCopyRecursive"))
	assert_false(DirAccess.dir_exists_absolute(PROJECTS[1] + "EmptyDir/MessyDirCopyNotRecursive"))
	
	# Setup
	Data.load_project(PROJECTS[1])
	Data.current_routine = Data.routines[ROUTINES.copy_files]
	
	# Execute
	add_child.call_deferred(scene)
	await wait_for_signal(scene.finished, EXECUTION_TIMEOUT)
	
	# Check results
	assert_true(FileAccess.file_exists(PROJECTS[1] + "file1.txt"))
	assert_true(DirAccess.dir_exists_absolute(PROJECTS[1] + "MessyDir"))
	
	assert_true(FileAccess.file_exists(PROJECTS[1] + "file1-copy.txt"))
	assert_true(FileAccess.file_exists(PROJECTS[1] + "EmptyDir/file1-copy.txt"))
	
	assert_true(FileAccess.file_exists(PROJECTS[1] + "EmptyDir/MessyDirCopyRecursive/a.txt"))
	assert_true(FileAccess.file_exists(PROJECTS[1] + "EmptyDir/MessyDirCopyRecursive/b.txt"))
	assert_true(FileAccess.file_exists(PROJECTS[1] + "EmptyDir/MessyDirCopyRecursive/Dir/c.txt"))
	
	assert_true(FileAccess.file_exists(PROJECTS[1] + "EmptyDir/MessyDirCopyNotRecursive/a.txt"))
	assert_true(FileAccess.file_exists(PROJECTS[1] + "EmptyDir/MessyDirCopyNotRecursive/b.txt"))
	assert_false(DirAccess.dir_exists_absolute(PROJECTS[1] + "EmptyDir/MessyDirCopyNotRecursive/Dir"))

	# Cleanup
	DirAccess.remove_absolute(PROJECTS[1] + "file1-copy.txt")
	DirAccess.remove_absolute(PROJECTS[1] + "EmptyDir/file1-copy.txt")
	
	DirAccess.remove_absolute(PROJECTS[1] + "EmptyDir/MessyDirCopyRecursive/a.txt")
	DirAccess.remove_absolute(PROJECTS[1] + "EmptyDir/MessyDirCopyRecursive/b.txt")
	DirAccess.remove_absolute(PROJECTS[1] + "EmptyDir/MessyDirCopyRecursive/Dir/c.txt")
	DirAccess.remove_absolute(PROJECTS[1] + "EmptyDir/MessyDirCopyRecursive/Dir")
	DirAccess.remove_absolute(PROJECTS[1] + "EmptyDir/MessyDirCopyRecursive")
	
	DirAccess.remove_absolute(PROJECTS[1] + "EmptyDir/MessyDirCopyNotRecursive/a.txt")
	DirAccess.remove_absolute(PROJECTS[1] + "EmptyDir/MessyDirCopyNotRecursive/b.txt")
	DirAccess.remove_absolute(PROJECTS[1] + "EmptyDir/MessyDirCopyNotRecursive/Dir/c.txt")
	DirAccess.remove_absolute(PROJECTS[1] + "EmptyDir/MessyDirCopyNotRecursive/Dir")
	DirAccess.remove_absolute(PROJECTS[1] + "EmptyDir/MessyDirCopyNotRecursive")

func test_clear_directory_files():
	# Check assumptions
	assert_true(FileAccess.file_exists(PROJECTS[1] + "MessyDir/a.txt"))
	assert_true(FileAccess.file_exists(PROJECTS[1] + "MessyDir/b.txt"))
	assert_true(FileAccess.file_exists(PROJECTS[1] + "MessyDir/Dir/c.txt"))
	
	# Setup
	DirAccess.copy_absolute(PROJECTS[1] + "MessyDir/a.txt", PROJECTS[1] + "EmptyDir/a.txt")
	DirAccess.copy_absolute(PROJECTS[1] + "MessyDir/b.txt", PROJECTS[1] + "EmptyDir/b.txt")
	Data.load_project(PROJECTS[1])
	Data.current_routine = Data.routines[ROUTINES.clear_directory_files]
	
	# Execute
	add_child.call_deferred(scene)
	await wait_for_signal(scene.finished, EXECUTION_TIMEOUT)
	
	# Check results
	assert_false(FileAccess.file_exists(PROJECTS[1] + "MessyDir/a.txt"))
	assert_false(FileAccess.file_exists(PROJECTS[1] + "MessyDir/b.txt"))
	assert_true(FileAccess.file_exists(PROJECTS[1] + "MessyDir/Dir/c.txt"))

	# Cleanup
	DirAccess.rename_absolute(PROJECTS[1] + "EmptyDir/a.txt", PROJECTS[1] + "MessyDir/a.txt")
	DirAccess.rename_absolute(PROJECTS[1] + "EmptyDir/b.txt", PROJECTS[1] + "MessyDir/b.txt")

func test_pack_zip():
	# Check assumptions
	assert_true(DirAccess.dir_exists_absolute(PROJECTS[1] + "MessyDir"))
	assert_false(FileAccess.file_exists(PROJECTS[1] + "MessyDir.zip"))
	assert_false(FileAccess.file_exists(PROJECTS[1] + "Include.zip"))
	assert_false(FileAccess.file_exists(PROJECTS[1] + "Exclude.zip"))
	
	# Setup
	Data.load_project(PROJECTS[1])
	Data.current_routine = Data.routines[ROUTINES.pack_zip]
	
	# Execute
	add_child.call_deferred(scene)
	await wait_for_signal(scene.finished, EXECUTION_TIMEOUT)
	
	# Check results
	assert_true(DirAccess.dir_exists_absolute(PROJECTS[1] + "MessyDir"))
	assert_true(FileAccess.file_exists(PROJECTS[1] + "MessyDir.zip"))
	assert_true(FileAccess.file_exists(PROJECTS[1] + "Include.zip"))
	assert_true(FileAccess.file_exists(PROJECTS[1] + "Exclude.zip"))
	
	var reader := ZIPReader.new()
	var error := reader.open(PROJECTS[1] + "MessyDir.zip")
	var files := reader.get_files()
	reader.close()
	assert_true(error == OK)
	assert_true(files.has("a.txt"))
	assert_true(files.has("b.txt"))
	assert_true(files.has("Dir/c.txt"))
	
	reader = ZIPReader.new()
	error = reader.open(PROJECTS[1] + "Include.zip")
	files = reader.get_files()
	reader.close()
	assert_true(error == OK)
	assert_true(files.has("a.txt"))
	assert_false(files.has("b.txt"))
	assert_false(files.has("Dir/c.txt"))
	
	reader = ZIPReader.new()
	error = reader.open(PROJECTS[1] + "Exclude.zip")
	files = reader.get_files()
	reader.close()
	assert_true(error == OK)
	assert_false(files.has("a.txt"))
	assert_true(files.has("b.txt"))
	assert_true(files.has("Dir/c.txt"))

	# Cleanup
	DirAccess.remove_absolute(PROJECTS[1] + "MessyDir.zip")
	DirAccess.remove_absolute(PROJECTS[1] + "Include.zip")
	DirAccess.remove_absolute(PROJECTS[1] + "Exclude.zip")

func test_sub_routine():
	# Check assumptions
	assert_true(FileAccess.file_exists(PROJECTS[1] + "file1.txt"))
	assert_false(FileAccess.file_exists(PROJECTS[1] + "copy1.txt"))
	assert_false(FileAccess.file_exists(PROJECTS[1] + "copy2.txt"))
	assert_false(FileAccess.file_exists(PROJECTS[1] + "copy3.txt"))
	assert_false(FileAccess.file_exists(PROJECTS[1] + "copy4.txt"))
	
	# Setup
	Data.load_project(PROJECTS[1])
	Data.current_routine = Data.routines[ROUTINES.sub_routine]
	
	# Execute
	add_child.call_deferred(scene)
	await wait_for_signal(scene.finished, EXECUTION_TIMEOUT)
	
	# Check results
	assert_true(FileAccess.file_exists(PROJECTS[1] + "file1.txt"))
	assert_true(FileAccess.file_exists(PROJECTS[1] + "copy1.txt"))
	assert_true(FileAccess.file_exists(PROJECTS[1] + "copy2.txt"))
	assert_true(FileAccess.file_exists(PROJECTS[1] + "copy3.txt"))
	assert_true(FileAccess.file_exists(PROJECTS[1] + "copy4.txt"))

	# Cleanup
	DirAccess.remove_absolute(PROJECTS[1] + "copy1.txt")
	DirAccess.remove_absolute(PROJECTS[1] + "copy2.txt")
	DirAccess.remove_absolute(PROJECTS[1] + "copy3.txt")
	DirAccess.remove_absolute(PROJECTS[1] + "copy4.txt")

func test_cyclic_sub_routine_1():
	# Setup
	Data.load_project(PROJECTS[1])
	Data.current_routine = Data.routines[ROUTINES.cyclic_sub_routine_1]
	
	# Execute
	watch_signals(scene)
	add_child.call_deferred(scene)
	await wait_for_signal(scene.finished, EXECUTION_TIMEOUT)
	
	# Check results
	assert_signal_emitted(scene, "finished")

func test_cyclic_sub_routine_2():
	# Setup
	Data.load_project(PROJECTS[1])
	Data.current_routine = Data.routines[ROUTINES.cyclic_sub_routine_2]
	
	# Execute
	watch_signals(scene)
	add_child.call_deferred(scene)
	await wait_for_signal(scene.finished, EXECUTION_TIMEOUT)
	
	# Check results
	assert_signal_emitted(scene, "finished")
	
func test_bash_custom_task():
	if OS.get_name() == "Windows":
		pass_test("Will not test bash commands in Windows.")
		return
	elif OS.get_name() == "Android":
		pass_test("Will not test bash commands in Android.")
		return
	
	const filename := "BashFile.txt"
	
	# Check assumptions
	assert_false(FileAccess.file_exists(PROJECTS[1] + filename))
	
	# Setup
	Data.load_project(PROJECTS[1])
	Data.current_routine = Data.routines[ROUTINES.bash_custom_task]
	
	# Execute
	add_child.call_deferred(scene)
	await wait_for_signal(scene.finished, EXECUTION_TIMEOUT)
	
	# Check results
	assert_true(FileAccess.file_exists(PROJECTS[1] + filename))

	# Cleanup
	DirAccess.remove_absolute(PROJECTS[1] + filename)
	
func test_windows_custom_task():
	if OS.get_name() != "Windows":
		pass_test("Will only test Windows commands in Windows.")
		return
	
	const filename := "WindowsFile.txt"
	
	# Check assumptions
	assert_false(FileAccess.file_exists(PROJECTS[1] + filename))
	
	# Setup
	Data.load_project(PROJECTS[1])
	Data.current_routine = Data.routines[ROUTINES.windows_custom_task]
	
	# Execute
	add_child.call_deferred(scene)
	await wait_for_signal(scene.finished, EXECUTION_TIMEOUT)
	
	# Check results
	assert_true(FileAccess.file_exists(PROJECTS[1] + filename))

	# Cleanup
	DirAccess.remove_absolute(PROJECTS[1] + filename)
