#!/usr/bin/env python3
"""Restore the Kotlin runtime classes that the decompile dropped (Kotlin 1.8.22).

Closure = every type referenced by the project (code, member signatures, field
types, superclasses, interfaces *and* annotation types) that is neither defined
by the project nor provided by the platform, plus everything those classes
reference in turn, to a fixed point.

Sources: decompiled APKs whose bundled stdlib is Kotlin 1.8.22 - the exact
version this app was compiled against (kotlin/KotlinVersionCurrentValue in the
project's own tree reports 1.8.22, and the 778 classes present in both trees are
ABI-identical).  The official kotlin-stdlib-1.8.22.jar was verified to have
sha256 03a5c3965cc37051128e64e46748e394b6bd4c97fa81c6de6fc72bfd44e3421b.

    python3 scripts/restore_kotlin_runtime.py --universe <dir> [...] [--write]

Without --write the script only reports what it would copy.
"""
from __future__ import annotations

import argparse
import os
import shutil
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, '/tmp')
from linkcheck import scan_tree, is_platform, parse_smali  # noqa: E402

PROJECT = '/home/user/JVHD-apk'
ROOTS = [os.path.join(PROJECT, 'smali'), os.path.join(PROJECT, 'smali_classes2')]
DEST = os.path.join(PROJECT, 'smali_classes3')


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument('--universe', action='append', required=True,
                        help='root directory of a decompiled project (smali tree)')
    parser.add_argument('--write', action='store_true')
    args = parser.parse_args()

    ours = scan_tree(ROOTS)
    print(f'project: {len(ours)} classes')
    universe: dict[str, tuple[str, str]] = {}
    for root in args.universe:
        tree = scan_tree([root])
        for desc, info in tree.items():
            universe.setdefault(desc, (root, info.path))
        print(f'  universe {root}: {len(tree)} classes')

    merged = dict(ours)
    plan: dict[str, tuple[str, str]] = {}
    for _round in range(100):
        todo = []
        for info in merged.values():
            for t in info.all_type_refs:
                if t not in merged and not is_platform(t) and t not in plan:
                    todo.append(t)
        todo = sorted(set(todo))
        if not todo:
            break
        for t in todo:
            if t in universe:
                root, path = universe[t]
                plan[t] = (root, path)
                merged[t] = parse_smali(path, open(path, encoding='utf-8', errors='replace').read())
            else:
                print(f'  !! cannot resolve {t}')

    print(f'\nclasses to restore: {len(plan)}')
    from collections import Counter
    per_source = Counter(root for root, _ in plan.values())
    for root, count in sorted(per_source.items()):
        print(f'  {count:4d}  {root}')

    if not args.write:
        return 0

    if os.path.isdir(DEST):
        shutil.rmtree(DEST)
    for desc, (root, path) in sorted(plan.items()):
        target = os.path.join(DEST, desc[1:-1] + '.smali')
        os.makedirs(os.path.dirname(target), exist_ok=True)
        shutil.copyfile(path, target)
    print(f'wrote {len(plan)} files to {DEST}')
    with open(os.path.join(PROJECT, 'smali_classes3', 'RESTORED-CLASSES.txt'), 'w') as handle:
        handle.write('# Kotlin 1.8.22 classes restored from version-matched decompiled\n'
                     '# APKs (see scripts/restore_kotlin_runtime.py). One descriptor per line.\n')
        for desc in sorted(plan):
            handle.write(desc + '\n')
    return 0


if __name__ == '__main__':
    sys.exit(main())
