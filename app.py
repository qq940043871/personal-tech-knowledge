from flask import Flask, jsonify, send_from_directory, request
import os
from pathlib import Path
import re

app = Flask(__name__)

WORKSPACE_PATH = Path(__file__).parent

def get_markdown_files():
    """获取工作空间中所有的 Markdown 文件"""
    md_files = []
    
    for root, dirs, files in os.walk(WORKSPACE_PATH):
        # 跳过隐藏目录
        dirs[:] = [d for d in dirs if not d.startswith('.')]
        
        for file in files:
            if file.endswith('.md'):
                full_path = Path(root) / file
                relative_path = full_path.relative_to(WORKSPACE_PATH)
                md_files.append(str(relative_path))
    
    return sorted(md_files)

def get_directory_structure():
    """获取目录结构"""
    structure = {}
    
    for root, dirs, files in os.walk(WORKSPACE_PATH):
        # 跳过隐藏目录
        dirs[:] = [d for d in dirs if not d.startswith('.')]
        
        relative_path = Path(root).relative_to(WORKSPACE_PATH)
        
        # 获取当前目录的 Markdown 文件
        md_files = [f for f in files if f.endswith('.md')]
        
        if md_files or relative_path == Path('.'):
            if str(relative_path) == '.':
                structure[''] = md_files
            else:
                structure[str(relative_path)] = md_files
    
    return structure

def organize_files_by_category():
    """按类别组织文件，支持2列布局"""
    structure = get_directory_structure()
    categories = []
    
    for path, files in sorted(structure.items()):
        if files:
            category = {
                'path': path,
                'name': path if path else '根目录',
                'files': sorted(files)
            }
            categories.append(category)
    
    return categories

@app.route('/')
def index():
    return send_from_directory('.', 'index.html')

@app.route('/api/files')
def get_files():
    """获取所有 Markdown 文件列表"""
    categories = organize_files_by_category()
    return jsonify(categories)

@app.route('/api/file')
def get_file_content():
    """获取指定文件的内容"""
    file_path = request.args.get('path')
    if not file_path:
        return jsonify({'error': 'No file path provided'}), 400
    
    full_path = WORKSPACE_PATH / file_path
    
    if not full_path.exists() or not full_path.is_file():
        return jsonify({'error': 'File not found'}), 404
    
    try:
        with open(full_path, 'r', encoding='utf-8') as f:
            content = f.read()
        return jsonify({
            'path': file_path,
            'content': content
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(debug=True, port=5000)