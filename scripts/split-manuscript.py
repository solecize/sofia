#!/usr/bin/env python3
"""Split manuscript into chapters and separate notes."""

import re
from pathlib import Path

def main():
    manuscript_path = Path('notes/works/prince-of-loves/chapters/01-manuscript-draft.md')
    chapters_dir = Path('notes/works/prince-of-loves/chapters')
    
    manuscript = manuscript_path.read_text()
    lines = manuscript.split('\n')
    
    # Find notes section (starts with "PRINCE OF LOVES — COMPILED NOTES")
    notes_start = None
    for i, line in enumerate(lines):
        if 'COMPILED NOTES' in line:
            notes_start = i
            break
    
    if notes_start:
        prose_lines = lines[:notes_start]
        notes_lines = lines[notes_start:]
        
        # Write notes to separate file
        notes_path = Path('notes/works/prince-of-loves/reference-notes.md')
        notes_path.write_text('\n'.join(notes_lines))
        print(f"Wrote notes ({len(notes_lines)} lines) to {notes_path}")
    else:
        prose_lines = lines
        print("No notes section found")
    
    # Section headers to split on
    section_headers = [
        ('01', 'Synth Pop Sunday'),
        ('02', 'Thief Delivers A Song of Simon'),
        ('03', 'A Court of Sorts'),
        ('04', 'Nightlongs'),
        ('05', 'Cynthia Chapter A'),
        ('06', 'Simon Lost'),
        ('07', 'A Thief Dreamwalks'),
        ('08', 'The Wolf Passage'),
        ('09', 'Thief and Simon in the Dreamworld'),
        ('10', 'Gift dreamwalks'),
        ('11', 'Story dreamwalks and later campfire passages'),
        ('12', 'Simon Returns'),
    ]
    
    header_map = {title: num for num, title in section_headers}
    
    chapters = []
    current = None
    current_content = []
    
    for line in prose_lines:
        stripped = line.strip()
        if stripped in header_map:
            if current:
                chapters.append((current, current_content))
            current = (header_map[stripped], stripped)
            current_content = [f"# {stripped}\n"]
        elif current:
            current_content.append(line)
    
    if current:
        chapters.append((current, current_content))
    
    # Write chapters
    for (num, title), content in chapters:
        slug = re.sub(r'[^a-z0-9]+', '-', title.lower()).strip('-')
        filename = f"{num}-{slug}.md"
        filepath = chapters_dir / filename
        filepath.write_text('\n'.join(content))
        print(f"Wrote {filename} ({len(content)} lines)")
    
    # Remove old draft file
    if chapters:
        manuscript_path.unlink()
        print(f"\nRemoved {manuscript_path}")
    
    print(f"\nTotal: {len(chapters)} chapters")

if __name__ == '__main__':
    main()
