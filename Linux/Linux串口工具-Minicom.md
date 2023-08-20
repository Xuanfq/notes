## Modify settings

Input command `sudo minicom -s`

## Enter serial port

Input command `minicom -D /dev/ttyUSB* -b 115200`

## Related questions

*   若无串口输出以及无法输入，请尝试修改串口设置中的Hardware Flow Control设置为No并保存：

    1.  input command \`sudo minicom -s\`.
    2.  Select 'Serial port setup'.&#x20;
    3.  Press the 'F' key to modify 'Hardware Flow Control' to 'No', and than input enter.&#x20;
    4.  Select 'Save setup as dfl'&#x20;
    5.  Select 'Exit' to exit.
*   If sending files with Xmodem fails, please install lrzsz under Linux, which has the xmodem protocol.


