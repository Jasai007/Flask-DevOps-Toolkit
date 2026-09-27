#!/usr/bin/python
# -*- coding: utf-8 -*-
# =============================================================================
# local.demo.human_size - custom Jinja2 FILTER plugin (collection plugin)
# -----------------------------------------------------------------------------
# While MODULES act on hosts, FILTERS transform VALUES inside templates:
#     {{ 1536000 | local.demo.human_size }}            -> "1.5 MB"
#     {{ 1536000 | local.demo.human_size(binary=true) }} -> "1.5 MiB"
#
# A filter plugin is a plain Python class exposing a filters() dictionary:
#     filter name (Jinja)  ->  callable (Python)
#
# TRY IT:
#   ansible-playbook playbooks/20_collections.yml
#   ansible-doc -t filter local.demo.human_size   # if docstring is picked up
# =============================================================================
from __future__ import absolute_import, division, print_function

__metaclass__ = type

# Unit ladders: decimal (SI, powers of 1000) vs binary (IEC, powers of 1024).
DECIMAL_UNITS = ["B", "kB", "MB", "GB", "TB", "PB"]
BINARY_UNITS = ["B", "KiB", "MiB", "GiB", "TiB", "PiB"]


def human_size(size, binary=False, precision=1):
    """Convert a byte count into a human readable string.

    :param size:      numeric value (int/float/str-of-number) to convert
    :param binary:    False -> decimal units (kB/MB, 1000-based) - default
                      True  -> binary units (KiB/MiB, 1024-based)
    :param precision: decimals to keep after the point
    :returns:         e.g. "1.5 MB"
    :raises ValueError: when size is not a number or is negative

    Designed as a pure function so it is trivial to unit-test.
    """
    try:
        size = float(size)
    except (TypeError, ValueError):
        raise ValueError("human_size expects a number, got %r" % (size,))

    if size < 0:
        raise ValueError("human_size expects a non-negative number")

    units = BINARY_UNITS if binary else DECIMAL_UNITS
    step = 1024.0 if binary else 1000.0

    index = 0
    # Divide down until we fit the unit ladder (or run out of units).
    while abs(size) >= step and index < len(units) - 1:
        size /= step
        index += 1

    return "%.*f %s" % (precision, size, units[index])


class FilterModule(object):
    """Jinja2 filter plugin entry point - Ansible looks for this class."""

    def filters(self):
        """Publish our filters: name inside templates -> python callable."""
        return {
            "human_size": human_size,
        }
