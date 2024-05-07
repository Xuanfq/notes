# &#x20;简介

[Tera Term Language (TTL) (osdn.jp)](https://ttssh2.osdn.jp/manual/4/en/macro/syntax/index.html)

TTL is a simple interpreted language like BASIC. To learn TTL quickly, study the sample macro files in the distribution package and the [command reference](https://ttssh2.osdn.jp/manual/4/en/macro/command/index.html).

*   [TTL file](https://ttssh2.osdn.jp/manual/4/en/macro/syntax/file.html)
*   [Types](https://ttssh2.osdn.jp/manual/4/en/macro/syntax/types.html)
*   [Formats of constants](https://ttssh2.osdn.jp/manual/4/en/macro/syntax/formats.html)
*   [Identifiers and reserved words](https://ttssh2.osdn.jp/manual/4/en/macro/syntax/identifiers.html)
*   [Variables](https://ttssh2.osdn.jp/manual/4/en/macro/syntax/variables.html)
*   [Expressions and operators](https://ttssh2.osdn.jp/manual/4/en/macro/syntax/expressions.html)
*   [Line formats](https://ttssh2.osdn.jp/manual/4/en/macro/syntax/lineformats.html)

# File (脚本文件)

## Encoding

The Unicode (UTF-8, UTF-16BE, UTF-16LE) can be supported from Tera Term 4.102.

The TTL file was processed as ANSI CodePage in previous version.

## Supporting encoding

| encoding                        | support     |   |
| :------------------------------ | :---------- | - |
| Usually (ANSI CodePage)         | Support     |   |
| UTF-8 (with BOM)                | Support     |   |
| UTF-8 (without BOM)             | Support     |   |
| UTF-16BE (without BOM)          | Not support |   |
| UTF-16LE (without BOM)          | Not support |   |
| UTF-16 (with BE BOM)            | Support     |   |
| UTF-16 (with LE BOM)            | Support     |   |
| UTF-16 (without BOM = UTF-16BE) | Not support |   |

## Encoding determination

Tera Term determines the encoding as follows.

When BOM existsTera Term determines one of UTF-8, UTF-16BE and UTF-16LE from BOM type, next reading the file.When BOM does not exist

*   Reading the file as UTF-8.
*   Reading the file as CP\_ACP (same as before 4.102) when the file can not be decoded as UTF-8.

# Types (数据类型)

TTL have four kinds of data types:

## Integer

Signed 32 bit, from -2147483648 to 2147483647.\
Floating point operation is not supported.

## Character string

A sequence containing any character except NUL. The maximum length of a string is 511.

## Integer Array

The integer array can be used by using the [intdim](https://ttssh2.osdn.jp/manual/4/en/macro/command/intdim.html) macro command. The maximum index is 65536.\
The element of the array equals to the integer.\
The maximum number of the array is 256.

### intdim

Declare integer array variable. *(version 4.72 or later)*

```
intdim <array> <size>

```

#### Remarks

Defines the array of integer type having the \<size> entry. The \<size> range is from 1 to 65536 and the array index is 0-origin.\
The default value of the array is 0.

#### Example

```
; Fibonacci sequence
intdim fibonacci 20
fibonacci[0] = 0
fibonacci[1] = 1
for i 2 19
        fibonacci[i] = fibonacci[i-2] + fibonacci[i-1]
next

msg = ""
for i 0 19
        sprintf2 msg "%s%d, " msg fibonacci[i]
next

messagebox msg "result"

```

```
; binary search tree
N = 10
intdim a N
a[0] = 1
a[1] = 2
a[2] = 3
a[3] = 7
a[4] = 11
a[5] = 32
a[6] = 40
a[7] = 68
a[8] = 81
a[9] = 99

inputbox 'Search data?' 'User Input'
str2int key inputstr

flag = 0
low = 0
high = N - 1
while low <= high
	mid = (low + high) / 2
	if a[mid] == key then
		sprintf "Your data %d found in index %d." key mid
		messagebox inputstr 'Success'
		flag = 1
		break
	endif
	if a[mid] < key then
		low = mid + 1
	else
		high = mid - 1
	endif
endwhile

if flag == 0 then
	messagebox 'Your data not found.' 'Failure'
endif
end

```

```
; sieve of Eratosthenes
;
; Example of execution result
; 3 5 7 11 13 17 19 23 29 31 37 41 43 47 53 59 61 [17 primes]
;

N = 30
intdim flag N+1
count = 0
for i 0 N
	flag[i] = 1
next

for i 0 N
	if flag[i] =1 then
		count = count + 1
		p = 2 * i + 3
		sprintf "%d " p
		dispstr inputstr

		k = i + p
		while k <= N
			flag[k] = 0
			k = k + p
		endwhile
	endif
next

sprintf "[%d primes]" count
dispstr inputstr

end

```

## String Array

The string array can be used by using the [strdim](https://ttssh2.osdn.jp/manual/4/en/macro/command/strdim.html) macro command. The maximum index is 65536.\
The element of the array equals to the string.\
The maximum number of the array is 256.

### strdim

Declare string array variable. *(version 4.72 or later)*

```
strdim <array> <size>

```

#### Remarks

Defines the array of integer type having the \<size> entry. The \<size> range is from 1 to 65536 and the array index is 0-origin.\
The default value of the array is an empty string.

#### Example

```
strdim timeary 10
for i 9 0
        gettime timeary[9-i]
        statusbox i "wait"
        pause 1
next

msg = ""
for i 0 9
        strconcat msg timeary[i]
        strconcat msg #13#10
next

messagebox msg "result"

```

# Formats of constants (常量格式)

## 1) Integer-type constants

A integer-type constant is expressed as a decimal number or a hexadecimal number which begins with a "\$" character. Floating point operation is not supported.

```
Example:
    123
    -11
    $3a
    $10F

```

### [Note on negative integer constants](https://ttssh2.osdn.jp/manual/4/en/macro/appendixes/negative.html)

Using a negative integer constant may cause a problem like the following: For example,

    for i 5 -1

causes the syntax error, because the second parameter is regarded as "5-1" instead of "5" and the third parameter is empty. To avoid this problem, take one of the following solutions:

1.  Put "0" before "-".

        for i 5 0-1
2.  Add parenthese.

        for i 5 (-1)
3.  Assign the negative constant to a variable.

    ```

    A = -1
    for i 5 A
    ```

## 2) String-type constants

There are two ways of expressing a string-type constant.

a) A character string quoted by ' or " (both sides must be same).

```
Example:
    'Hello, world'
    "I can't do that"

```

b) A single character expressed as a "#" followed by an ASCII code (decimal or hexadecimal number). Note: Strings can not contain NUL (ASCII code 0) characters.

```
Example:
    #65     The character "A".
    #$41    The character "A".
    #13     The CR character.

```

[ASCII code table](https://ttssh2.osdn.jp/manual/4/en/macro/appendixes/ascii.html)

Format a) and b) can be combined in one expression.

    Example:
        'cat readme.txt'#13#10
        'abc'#$0d#$0a'def'#$0d#$0a'ghi'

# Identifiers and reserved words (标识符和保留字)

## Variable identifiers

The first character must be an alphabetic (A-Z, a-z) or an underscore character "\_". Subsequent characters can be alphabetic, underscore or numeric (0-9). Variable identifiers are not case-sensitive. The maximum length is 32.

```
Example:
    VARIABLE
    _flag

```

## Label identifiers

Label identifiers consist of alphabetic, underscore or numeric characters, and are not case-sensitive. The maximum length is 32.

```
Example:
    label1
    100

```

## Reserved words

The following words are reserved:

Commandbplusrecv, bplussend, changedir... (see the [command list](https://ttssh2.osdn.jp/manual/4/en/macro/command/index.html))Operatorand, not, or, xorSystem variablegroupmatchstr1, groupmatchstr2, groupmatchstr3, groupmatchstr4, groupmatchstr5, groupmatchstr6, groupmatchstr7, groupmatchstr8, groupmatchstr9,\
param1, param2, param3, param4, param5, param6, param7, param8, param9, params, paramcnt,\
inputstr, matchstr, result, timeout, mtimeout

# Variables

**1) User variables**

Defined by user. The type of a variable is determined when a value (integer or string) is assigned to it for the first time. Once the type of the variable is determined, values of a different type cannot be assigned to it.

**2) System variables**

Each system variable has a predefined type and value. Used with particular commands.

| Variables                                                                            | Type            | Initial value                                                               | Related commands                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
| :----------------------------------------------------------------------------------- | :-------------- | :-------------------------------------------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| groupmatchstr1 ... groupmatchstr9                                                    | string          | ""                                                                          | [waitregex](https://ttssh2.osdn.jp/manual/4/en/macro/command/waitregex.html), [strjoin](https://ttssh2.osdn.jp/manual/4/en/macro/command/strjoin.html), [strsplit](https://ttssh2.osdn.jp/manual/4/en/macro/command/strsplit.html), [strmatch](https://ttssh2.osdn.jp/manual/4/en/macro/command/strmatch.html) [strreplace](https://ttssh2.osdn.jp/manual/4/en/macro/command/strreplace.html)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| inputstr                                                                             | string          | ""                                                                          | [recvln](https://ttssh2.osdn.jp/manual/4/en/macro/command/recvln.html), [waitln](https://ttssh2.osdn.jp/manual/4/en/macro/command/waitln.html), [waitn](https://ttssh2.osdn.jp/manual/4/en/macro/command/waitn.html), [waitrecv](https://ttssh2.osdn.jp/manual/4/en/macro/command/waitrecv.html), [waitregex](https://ttssh2.osdn.jp/manual/4/en/macro/command/waitregex.html), [sprintf](https://ttssh2.osdn.jp/manual/4/en/macro/command/sprintf.html), [passwordbox](https://ttssh2.osdn.jp/manual/4/en/macro/command/passwordbox.html), [filenamebox](https://ttssh2.osdn.jp/manual/4/en/macro/command/filenamebox.html), [inputbox](https://ttssh2.osdn.jp/manual/4/en/macro/command/inputbox.html)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| matchstr                                                                             | string          | ""                                                                          | [waitregex](https://ttssh2.osdn.jp/manual/4/en/macro/command/waitregex.html), [strmatch](https://ttssh2.osdn.jp/manual/4/en/macro/command/strmatch.html)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| param1, param2 ... param9                                                            | string, integer | [\*1](https://ttssh2.osdn.jp/manual/4/en/macro/syntax/variables.html#note1) | [\*1](https://ttssh2.osdn.jp/manual/4/en/macro/syntax/variables.html#note1)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| params                                                                               | string array    | [\*1](https://ttssh2.osdn.jp/manual/4/en/macro/syntax/variables.html#note1) | [\*1](https://ttssh2.osdn.jp/manual/4/en/macro/syntax/variables.html#note1)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| paramcnt                                                                             | integer         | [\*1](https://ttssh2.osdn.jp/manual/4/en/macro/syntax/variables.html#note1) | [\*1](https://ttssh2.osdn.jp/manual/4/en/macro/syntax/variables.html#note1)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| result                                                                               | integer         | 0                                                                           | [bplusrecv](https://ttssh2.osdn.jp/manual/4/en/macro/command/bplusrecv.html), [bplussend](https://ttssh2.osdn.jp/manual/4/en/macro/command/bplussend.html), [checksum8file](https://ttssh2.osdn.jp/manual/4/en/macro/command/checksum8.html), [checksum16file](https://ttssh2.osdn.jp/manual/4/en/macro/command/checksum16.html), [checksum32file](https://ttssh2.osdn.jp/manual/4/en/macro/command/checksum32.html), [clipb2var](https://ttssh2.osdn.jp/manual/4/en/macro/command/clipb2var.html), [connect](https://ttssh2.osdn.jp/manual/4/en/macro/command/connect.html), [crc16file](https://ttssh2.osdn.jp/manual/4/en/macro/command/crc16.html), [crc32file](https://ttssh2.osdn.jp/manual/4/en/macro/command/crc32.html), [cygconnect](https://ttssh2.osdn.jp/manual/4/en/macro/command/cygconnect.html), [dirnamebox](https://ttssh2.osdn.jp/manual/4/en/macro/command/dirnamebox.html), [exec](https://ttssh2.osdn.jp/manual/4/en/macro/command/exec.html), [fileconcat](https://ttssh2.osdn.jp/manual/4/en/macro/command/fileconcat.html), [filecopy](https://ttssh2.osdn.jp/manual/4/en/macro/command/filecopy.html), [filecreate](https://ttssh2.osdn.jp/manual/4/en/macro/command/filecreate.html), [filedelete](https://ttssh2.osdn.jp/manual/4/en/macro/command/filedelete.html), [filelock](https://ttssh2.osdn.jp/manual/4/en/macro/command/filelock.html), [filenamebox](https://ttssh2.osdn.jp/manual/4/en/macro/command/filenamebox.html), [fileread](https://ttssh2.osdn.jp/manual/4/en/macro/command/fileread.html), [filereadln](https://ttssh2.osdn.jp/manual/4/en/macro/command/filereadln.html), [filerename](https://ttssh2.osdn.jp/manual/4/en/macro/command/filerename.html), [filesearch](https://ttssh2.osdn.jp/manual/4/en/macro/command/filesearch.html), [filestat](https://ttssh2.osdn.jp/manual/4/en/macro/command/filestat.html), [filestrseek](https://ttssh2.osdn.jp/manual/4/en/macro/command/filestrseek.html), [filestrseek2](https://ttssh2.osdn.jp/manual/4/en/macro/command/filestrseek2.html), [filetruncate](https://ttssh2.osdn.jp/manual/4/en/macro/command/filetruncate.html), [fileunlock](https://ttssh2.osdn.jp/manual/4/en/macro/command/fileunlock.html), [findfirst](https://ttssh2.osdn.jp/manual/4/en/macro/command/findoperations.html), [findnext](https://ttssh2.osdn.jp/manual/4/en/macro/command/findoperations.html), [getdate](https://ttssh2.osdn.jp/manual/4/en/macro/command/getdate.html), [getfileattr](https://ttssh2.osdn.jp/manual/4/en/macro/command/getfileattr.html), [getipv4addr](https://ttssh2.osdn.jp/manual/4/en/macro/command/getipv4addr.html), [getipv6addr](https://ttssh2.osdn.jp/manual/4/en/macro/command/getipv6addr.html), [getmodemstatus](https://ttssh2.osdn.jp/manual/4/en/macro/command/getmodemstatus.html), [getpassword](https://ttssh2.osdn.jp/manual/4/en/macro/command/getpassword.html), [getspecialfolder](https://ttssh2.osdn.jp/manual/4/en/macro/command/getspecialfolder.html), [gettime](https://ttssh2.osdn.jp/manual/4/en/macro/command/gettime.html), [getttdir](https://ttssh2.osdn.jp/manual/4/en/macro/command/getttdir.html), [getver](https://ttssh2.osdn.jp/manual/4/en/macro/command/getver.html), [ifdefined](https://ttssh2.osdn.jp/manual/4/en/macro/command/ifdefined.html), [ispassword](https://ttssh2.osdn.jp/manual/4/en/macro/command/ispassword.html), [kmtfinish](https://ttssh2.osdn.jp/manual/4/en/macro/command/kmtfinish.html), [kmtget](https://ttssh2.osdn.jp/manual/4/en/macro/command/kmtget.html), [kmtrecv](https://ttssh2.osdn.jp/manual/4/en/macro/command/kmtrecv.html), [kmtsend](https://ttssh2.osdn.jp/manual/4/en/macro/command/kmtsend.html), [listbox](https://ttssh2.osdn.jp/manual/4/en/macro/command/listbox.html), [loginfo](https://ttssh2.osdn.jp/manual/4/en/macro/command/loginfo.html), [logopen](https://ttssh2.osdn.jp/manual/4/en/macro/command/logopen.html), [quickvanrecv](https://ttssh2.osdn.jp/manual/4/en/macro/command/quickvanrecv.html), [quickvansend](https://ttssh2.osdn.jp/manual/4/en/macro/command/quickvansend.html), [recvln](https://ttssh2.osdn.jp/manual/4/en/macro/command/recvln.html), [foldercreate](https://ttssh2.osdn.jp/manual/4/en/macro/command/setfileattr.html), [folderdelete](https://ttssh2.osdn.jp/manual/4/en/macro/command/setfileattr.html), [foldersearch](https://ttssh2.osdn.jp/manual/4/en/macro/command/setfileattr.html), [setfileattr](https://ttssh2.osdn.jp/manual/4/en/macro/command/setfileattr.html), [setpassword](https://ttssh2.osdn.jp/manual/4/en/macro/command/setpassword.html), [sprintf](https://ttssh2.osdn.jp/manual/4/en/macro/command/sprintf.html), [sprintf2](https://ttssh2.osdn.jp/manual/4/en/macro/command/sprintf2.html), [str2int](https://ttssh2.osdn.jp/manual/4/en/macro/command/str2int.html), [strcompare](https://ttssh2.osdn.jp/manual/4/en/macro/command/strcompare.html), [strlen](https://ttssh2.osdn.jp/manual/4/en/macro/command/strlen.html), [strmatch](https://ttssh2.osdn.jp/manual/4/en/macro/command/strmatch.html), [strreplace](https://ttssh2.osdn.jp/manual/4/en/macro/command/strreplace.html), [strscan](https://ttssh2.osdn.jp/manual/4/en/macro/command/strscan.html), [strsplit](https://ttssh2.osdn.jp/manual/4/en/macro/command/strsplit.html), [testlink](https://ttssh2.osdn.jp/manual/4/en/macro/command/testlink.html), [var2clipb](https://ttssh2.osdn.jp/manual/4/en/macro/command/var2clipb.html), [wait](https://ttssh2.osdn.jp/manual/4/en/macro/command/wait.html), [wait4all](https://ttssh2.osdn.jp/manual/4/en/macro/command/wait4all.html), [waitevent](https://ttssh2.osdn.jp/manual/4/en/macro/command/waitevent.html), [waitln](https://ttssh2.osdn.jp/manual/4/en/macro/command/waitln.html), [waitn](https://ttssh2.osdn.jp/manual/4/en/macro/command/waitn.html), [waitrecv](https://ttssh2.osdn.jp/manual/4/en/macro/command/waitrecv.html), [waitregex](https://ttssh2.osdn.jp/manual/4/en/macro/command/waitregex.html), [xmodemrecv](https://ttssh2.osdn.jp/manual/4/en/macro/command/xmodemrecv.html), [xmodemsend](https://ttssh2.osdn.jp/manual/4/en/macro/command/xmodemsend.html), [yesnobox](https://ttssh2.osdn.jp/manual/4/en/macro/command/yesnobox.html), [ymodemrecv](https://ttssh2.osdn.jp/manual/4/en/macro/command/ymodemrecv.html), [ymodemsend](https://ttssh2.osdn.jp/manual/4/en/macro/command/ymodemsend.html), [zmodemrecv](https://ttssh2.osdn.jp/manual/4/en/macro/command/zmodemrecv.html), [zmodemsend](https://ttssh2.osdn.jp/manual/4/en/macro/command/zmodemsend.html) |
| timeout                                                                              | integer         | 0                                                                           | [recvln](https://ttssh2.osdn.jp/manual/4/en/macro/command/recvln.html), [wait](https://ttssh2.osdn.jp/manual/4/en/macro/command/wait.html), [wait4all](https://ttssh2.osdn.jp/manual/4/en/macro/command/wait4all.html), [waitevent](https://ttssh2.osdn.jp/manual/4/en/macro/command/waitevent.html), [waitn](https://ttssh2.osdn.jp/manual/4/en/macro/command/waitn.html), [waitln](https://ttssh2.osdn.jp/manual/4/en/macro/command/waitln.html), [waitrecv](https://ttssh2.osdn.jp/manual/4/en/macro/command/waitrecv.html), [waitregex](https://ttssh2.osdn.jp/manual/4/en/macro/command/waitregex.html)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| mtimeout [\*2](https://ttssh2.osdn.jp/manual/4/en/macro/syntax/variables.html#note2) | integer         | 0                                                                           | [recvln](https://ttssh2.osdn.jp/manual/4/en/macro/command/recvln.html), [wait](https://ttssh2.osdn.jp/manual/4/en/macro/command/wait.html), [wait4all](https://ttssh2.osdn.jp/manual/4/en/macro/command/wait4all.html), [waitevent](https://ttssh2.osdn.jp/manual/4/en/macro/command/waitevent.html), [waitn](https://ttssh2.osdn.jp/manual/4/en/macro/command/waitn.html), [waitln](https://ttssh2.osdn.jp/manual/4/en/macro/command/waitln.html), [waitrecv](https://ttssh2.osdn.jp/manual/4/en/macro/command/waitrecv.html), [waitregex](https://ttssh2.osdn.jp/manual/4/en/macro/command/waitregex.html)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |

*   [\*1](https://ttssh2.osdn.jp/manual/4/en/macro/syntax/variables.html#ref1) When MACRO program is started, the first parameter(macro filename) is stored into param1 and params\[1]. From the second to the ninth parameters are stored into from param2 to param9, and from params\[2] to params\[9]. The tenth or later parameter is stored into params\[10] or later. Please refer to [Command line](https://ttssh2.osdn.jp/manual/4/en/macro/commandline.html).
*   [\*2](https://ttssh2.osdn.jp/manual/4/en/macro/syntax/variables.html#ref2) Precision is about 50 msec.

# Expressions and operators (表达式和运算符)

Expressions consist of constants, variables, operators, and parentheses(括号). Constants and variables must be of the integer type. The value of an expression is also an integer.\
The value of a relational expression (formed using relational operators) is 1, if it is true, or 0 if false.

The following are operators:

| Precedence | Operators        | Category                                                 | Note                                                  |
| :--------- | :--------------- | :------------------------------------------------------- | :---------------------------------------------------- |
| 1, high    | not \~           | bitwise negation                                         | "\~" is available in version 4.53 or later            |
| !          | logical negation | available in version 4.53 or later                       |                                                       |
| +          | plus unary       |                                                          |                                                       |
| -          | minus unary      |                                                          |                                                       |
| 2          | \*               | multiplication                                           |                                                       |
| /          | division         |                                                          |                                                       |
| %          | remainder        | the value of expression A % B is the remainder of A / B. |                                                       |
| 3          | +                | addition                                                 |                                                       |
| -          | subtraction      |                                                          |                                                       |
| 4          | >> <<            | arithmetic shift                                         | available in version 4.54 or later                    |
| >>>        | logical shift    | available in version 4.54 or later                       |                                                       |
| 5          | and &            | bitwise conjunction                                      | "&" is available in version 4.53 or later             |
| 6          | xor ^            | bitwise exclusive disjunction                            | "^" is available in version 4.53 or later.            |
| 7          | or \|            | bitwise disjunction                                      | "\|" is available in version 4.53 or later.           |
| 8          | < > <= >=        | relational                                               |                                                       |
| 9          | = == <> !=       | relational                                               | "==" and "!=" are available in version 4.54 or later. |
| 10         | &&               | logical conjunction                                      | version 4.53 or later.                                |
| 11, low    | \|\|             | logical disjunction                                      | version 4.53 or later.                                |

"and", "or", "xor" and "not" are bitwise operator, not logical operator.

    Example:
        1 + 1
        4 - 2 * 3      The value is -2.
        15 % 10        The value is 5.
        3 * (A + 2)    A is an integer variable.
        A and not B
        A <= B         A and B are integer variables. The value is 1,
                       if the expression is true, or 0 if false.

# Line formats (行格式)

There are four kinds of line formats for macro files. Any line can contain a comment which begins with a ";" character. Also, a user can use the C language style comment(/\* - \*/).\
Comments give no effect on the execution of MACRO.\
One line can contain up to 1023 characters. The part that exceeded 1023 characters is ignored.

## 1) Empty lines

Lines which have no character or contain only space or tab characters or a comment. They give no effect on the execution of the macro.

```
Example:
    ; Tera Term Language

```

```
Example:
    showtt 0 
    MessageBox 'message 1' 'title 1' 
    /* This is 'comment' "string" 
    */ MessageBox 'message 2' 'title 2'
    closett

```

## 2) Command lines

Lines containing a single command with parameters.

```
Format:
    <command> <parameter> ...

Example:
    connect 'myhost'
    wait 'OK' 'ERROR'
    if result=2 goto error
    sendln 'cat'
    pause A*10
    end

```

## 3) Assignment lines

Lines which contain an assignment statement.

```
Format:
    <Variable> = <Value (constant, variable, expression)>

Example:
    A = 33
    B = C            C must already have a value.
    VAL = I*(I+1)	
    A=B=C            The value of B=C (0 for false, 1 for true) is assigned to A.
    Error=0<J	
    Username='MYNAME'

```

## 4) Label lines

Lines which begin with a ':' character followed by a label identifier.

    Format:
        :<Label>

    Example:
        :dial
        :100

end
