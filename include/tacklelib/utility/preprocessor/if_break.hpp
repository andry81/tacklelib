#pragma once

// DO NOT REMOVE, exists to avoid private/public headers mixing!
#ifndef UTILITY_PREPROCESSOR_IF_BREAK_HPP
#define UTILITY_PREPROCESSOR_IF_BREAK_HPP

// non breakable if with continue only label
#define if_goto_c(continue_label, x) continue_label: if(x)

// non breakable if with break only label
#define if_goto_b(break_label, x) if(false) break_label:; else if(x)

// non breakable if with continue and break labels
#define if_goto_cb(continue_label, break_label, x) continue_label: if(false) break_label:; else if(x)

// breakable if
#define if_break(x) switch(0) case 0: default: if(x)

// breakable if with continue only label
#define if_break_c(continue_label, x) switch(0) case 0: default: if_goto_c(continue_label, x)

// breakable if with break only label
#define if_break_b(break_label, x) switch(0) case 0: default: if_goto_b(break_label, x)

// breakable if with continue and break labels
#define if_break_cb(continue_label, break_label, x) switch(0) case 0: default: if_goto_cb(continue_label, break_label, x)

#endif
