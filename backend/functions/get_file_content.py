import os
from config import MAX_CHARS
from google.genai import types


def get_file_content(working_directory, file_path):
    abs_working_dir = os.path.abspath(working_directory)

    if not os.path.isabs(file_path):
        target_file = os.path.abspath(os.path.join(working_directory, file_path))
    else:
        target_file = os.path.abspath(file_path)
    
    if not target_file.startswith(abs_working_dir):
        return f'Error: Cannot read "{file_path}" as it is outside the permitted working directory'
    if os.path.isdir(target_file):
        return f'Error: "{file_path}" is a directory'
    if not os.path.exists(target_file):
        return f'Error: "{file_path}" does not exist'
    if not os.path.isfile(target_file):
        return f'Error: "{file_path}" is not a file'
    
    try:
        file_size = os.path.getsize(target_file)
        
        with open(target_file, "r", encoding="utf-8") as f:
            if file_size > MAX_CHARS:
                error = f' [...File "{file_path}" truncated at 10000 characters]'
                return f.read(MAX_CHARS) + error
            return f.read(MAX_CHARS)
            
    except Exception as e:
        return f"Error reading file: {e}"
    
schema_get_file_content = types.FunctionDeclaration(
    name="get_file_content",
    description=f"Reads and returns the first {MAX_CHARS} characters of the content from a specified file within the working directory.",
    parameters=types.Schema(
        type=types.Type.OBJECT,
        properties={
            "file_path": types.Schema(
                type=types.Type.STRING,
                description="The path to the file whose content should be read, relative to the working directory.",
            ),
        },
        required=["file_path"],
    ),
)