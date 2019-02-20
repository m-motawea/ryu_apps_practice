#!/usr/bin/env python
# -*- coding: utf-8 -*-

import sys

from ryu.cmd import manager


def main():
    sys.argv.append('lldp_topology_mapper.lldp')
    sys.argv.append('--verbose')
    sys.argv.append('--enable-debugger')
    manager.main()

if __name__ == '__main__':
    main()