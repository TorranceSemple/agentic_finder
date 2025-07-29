from functions.get_files_info import get_files_info
from functions.get_file_content import get_file_content
from functions.write_file import write_file
from functions.run_python import run_python_file


def test_info():
    result = get_files_info("calculator", ".")
    print("Result for current directory:")
    print(result)
    print("")

    result = get_files_info("calculator", "pkg")
    print("Result for 'pkg' directory:")
    print(result)

    result = get_files_info("calculator", "/bin")
    print("Result for '/bin' directory:")
    print(result)

    result = get_files_info("calculator", "../")
    print("Result for '../' directory:")
    print(result)

def test_file():
    result = get_file_content("calculator", "main.py")
    print(result)
    print("========================")
    
    result = get_file_content("calculator", "pkg/calculator.py")
    print(result)
    print("========================")
    
    result = get_file_content("calculator", "/bin/cat")
    print(result)

def test_write_file():
    result = write_file("calculator", "lorem.txt", "wait, this isn't lorem ipsum")
    print(result)
    print("========================")
    
    result = write_file("calculator", "pkg/morelorem.txt", "lorem ipsum dolor sit amet")
    print(result)
    print("========================")
    
    result = write_file("calculator", "/tmp/temp.txt", "this should not be allowed")
    print(result)
    print("========================")

def test_run():
    result = run_python_file("calculator", "main.py")
    print(result)
    print("========================")
    
    result = run_python_file("calculator", "tests.py")
    print(result)
    print("========================")
    
    result = run_python_file("calculator", "../main.py")
    print(result)
    print("========================")
    
    result = run_python_file("calculator", "nonexistent.py")
    print(result)
    print("========================")

if __name__ == "__main__":
    test_run()