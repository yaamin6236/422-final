# 422-final C Standard Library in ARM Assembly

This project implements a subset of the C standard library at the assembly level for a Thumb-2 target on TM4C129 microcontroller. The implementation includes basic functions (bzero, strncpy) and system call functions (malloc, free, signal, alarm) with a buddy memory allocation system.

## Project Overview

This project involves:
1. Implementing basic C functions in ARM assembly
2. Creating a buddy memory allocation system
3. Implementing system calls using the SVC mechanism
4. Using the SysTick timer for alarm functionality

## Getting Started

### Prerequisites
- Keil µVision5 installed
- Git for version control
- GCC compiler (for testing C implementation of buddy allocator)

### Cloning the Repository

```bash
git clone https://github.com/your-username/your-repo-name.git
cd your-repo-name
```

### Setting Up in Keil µVision

1. Open Keil µVision
2. Select `Project > Open Project`
3. Navigate to the cloned repository and open the `.uvprojx` file
4. The project structure should load with all necessary files

### Debugging Instructions
1. Configure simulator: `Project > Options for Target > Debug tab > Use Simulator`
2. Build: `Project > Build Target` (F7)
3. Start debugging: `Debug > Start/Stop Debug Session` (Ctrl+F5)
4. Debug controls:
  - Run (F5), Stop, Reset
  - Step (F11), Step Over (F10), Step Out
  - Set breakpoints by clicking in the margin
5. View memory: `View > Memory Window`
  - MCB area: 0x20006800-0x20006BFF
  - System calls: 0x20007B00
  - Timer variables: 0x20007B80, 0x20007B84
6. End debugging: `Debug > Start/Stop Debug Session`

If files are missing:
1. Right-click on "Source Group 1" in the Project panel
2. Select "Add Existing Files to Group..."
3. Navigate to the repository directory and add the required files

## Project Structure

### Template Files
The project starts with these template files which need to be modified:

- **startup_TM4C129.s**: Handles reset sequence and interrupt vectors
- **stdlib_template.s**: Contains user-mode library functions
- **svc_template.s**: Implements system call table and handlers
- **heap_template.s**: Buddy allocator implementation in assembly
- **timer_template.s**: Timer functions for alarm and signal handling
- **heap_template.c**: C implementation of buddy allocator (step 1)

### Driver Files
Three driver files are provided for testing:

- **driver.c**: Complete Linux/C program for simulation testing
- **driver_cpg.c**: C test program for the buddy allocator (step 1)
- **driver_keil.c**: Keil-compatible driver that calls assembly routines

## Implementation Roadmap

### Step 1: Basic Functionality & C-based Buddy Allocator
1. Modify reset sequence in `startup_TM4C129.s` to call `__main`
2. Implement `_bzero` and `_strncpy` in `stdlib_template.s`
3. Create a C version of the buddy allocator in `heap.c`
4. Test using `driver_cpg.c`

### Step 2: Full Assembly Implementation
1. Implement system call table in `svc.s`
2. Update `stdlib.s` to use proper SVC instructions
3. Implement buddy allocator in assembly (`heap.s`)
4. Create timer functions in assembly (`timer.s`)
5. Update startup file with proper handlers
6. Test using `driver_keil.c`

## Memory Layout

- **MCB Area**: 0x20006800 to 0x20006BFF
- **System Call Table**: 0x20007B00
- **Timer Variables**: 
  - SECOND_LEFT: 0x20007B80
  - USR_HANDLER: 0x20007B84

## System Call Numbers
- R7 = 0: Reserved
- R7 = 1: alarm (calls `_timer_start`)
- R7 = 2: signal (calls `_signal_handler`)
- R7 = 3: malloc (calls `_kalloc`)
- R7 = 4: free (calls `_kfree`)

## Testing Guidelines

### Testing C Implementation
```bash
gcc *.c -o a.out
./a.out
```

### Testing in Keil
1. Build the project
2. Start debug session
3. Set breakpoints in SVC_Handler, SysTick_Handler, and allocation routines
4. Use Memory window to examine:
   - MCB Area (0x20006800 to 0x20006BFF)
   - Timer Variables (0x20007B80 and 0x20007B84)
   - Stack Pointers (MSP and PSP)

## Contributing Guidelines

1. **File Naming**:
   - When implementing, rename the template files by removing "_template" suffix
   - Keep all function names exactly as specified with underscore prefix

2. **Implementation Order**:
   - Complete and test Step 1 before moving to Step 2
   - Test incrementally after implementing each component

3. **Code Documentation**:
   - Add comments explaining the logic of complex operations
   - Document any assumptions or design decisions

4. **Debugging**:
   - Take memory snapshots at key points as required
   - Save screenshots for your project report

## Submission Requirements

Your final project should include:
- All implemented assembly files
- Properly modified startup file
- C implementation of buddy allocator
- Memory snapshots and debugging evidence
- A report explaining your implementation

## Helpful Resources

- ARM Architecture Reference Manual
- TM4C129 Datasheet and Technical Reference Manual
- ARM Assembly Programming tutorials
- Buddy memory allocation system references
