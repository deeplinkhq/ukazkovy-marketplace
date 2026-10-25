#!/usr/bin/env python3
"""Build or check self-contained plugin payloads from .agents/plugins.json (Python 3.11+)."""
import argparse
import json
from pathlib import Path
import re
import shutil
import stat
import sys
import zipfile


def content(root: Path) -> dict[str, Path]:
    files = {}
    for path in sorted(root.rglob('*')):
        if path.is_symlink():
            raise ValueError('plugin source must contain physical files: ' + str(path))
        if path.is_file() and path.name != '.DS_Store' and '__pycache__' not in path.parts:
            files[path.relative_to(root).as_posix()] = path
    return files


def require_physical(root: Path, path: Path) -> None:
    current = root
    for part in path.relative_to(root).parts:
        current = current / part
        if current.is_symlink():
            raise ValueError('refusing symlink in physical path: ' + str(current))


def build(repo: Path, check: bool) -> int:
    repo = repo.resolve()
    require_physical(repo, repo / ".agents/plugins.json")
    stale = []
    spec = json.loads((repo / '.agents/plugins.json').read_text())
    for item in spec['plugins']:
        name, dest_name = item['source'], item['destination']
        if not re.fullmatch(r'[a-z0-9-]+', name) or not re.fullmatch(r'plugin-source|plugins/[a-z0-9-]+', dest_name):
            raise ValueError('invalid plugin source or destination')
        source = repo / '.agents/plugins' / name
        destination = repo / dest_name
        if source.is_symlink() or not source.resolve().is_relative_to(repo / '.agents/plugins'):
            raise ValueError('plugin source leaves canonical directory')
        if destination.is_symlink() or not destination.resolve().is_relative_to(repo):
            raise ValueError('plugin destination leaves repository')
        require_physical(repo, source)
        require_physical(repo, destination)
        payload = content(source)
        if 'archive' in item:
            filename = item['archive']
            if not re.fullmatch(r'[a-z0-9-]+\.plugin', filename):
                raise ValueError('archive must be a .plugin filename')
            archive = repo / filename
            require_physical(repo, archive)
            if archive.exists() and (not archive.is_file() or any(archive.samefile(f) for f in payload.values())):
                raise ValueError('archive aliases a source or is not a regular file')
        manifest = json.loads((source / '.claude-plugin/plugin.json').read_text())
        if not manifest.get('name') or not manifest.get('version'):
            raise ValueError('plugin requires name and version')
        existing = content(destination) if destination.exists() else {}
        matches = existing.keys() == payload.keys() and all(existing[k].read_bytes() == f.read_bytes() and (existing[k].stat().st_mode & 0o777) == (f.stat().st_mode & 0o777) for k, f in payload.items())
        if not matches:
            stale.append(dest_name)
            if not check:
                if destination.exists():
                    shutil.rmtree(destination)
                destination.parent.mkdir(parents=True, exist_ok=True)
                shutil.copytree(source, destination, ignore=shutil.ignore_patterns('.DS_Store','__pycache__'))
        if 'archive' in item:
            filename = item['archive']
            if not re.fullmatch(r'[a-z0-9-]+\.plugin', filename):
                raise ValueError('archive must be a .plugin filename')
            archive = repo / filename
            zip_matches = False
            if archive.exists():
                try:
                    with zipfile.ZipFile(archive) as z:
                        zip_matches = set(z.namelist()) == set(payload) and all(z.read(k) == f.read_bytes() and not stat.S_ISLNK(z.getinfo(k).external_attr >> 16) and ((z.getinfo(k).external_attr >> 16) & 0o777) == (f.stat().st_mode & 0o777) for k,f in payload.items())
                except zipfile.BadZipFile:
                    pass
            if not zip_matches:
                stale.append(filename)
                if not check:
                    with zipfile.ZipFile(archive, 'w', compression=zipfile.ZIP_DEFLATED) as z:
                        for key, file in payload.items():
                            info = zipfile.ZipInfo(key, (2026,1,1,0,0,0))
                            info.external_attr = (stat.S_IFREG | (file.stat().st_mode & 0o777)) << 16
                            info.compress_type = zipfile.ZIP_DEFLATED
                            z.writestr(info, file.read_bytes())
    if check and stale:
        print('Stale plugin payload: ' + ', '.join(stale))
        return 1
    print(('Checked' if check else 'Built') + ' plugin payloads (physical files)')
    return 0

if __name__ == '__main__':
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--check',action='store_true')
    p.add_argument('repo',nargs='?',default='.',type=Path)
    a=p.parse_args()
    sys.exit(build(a.repo.resolve(),a.check))
