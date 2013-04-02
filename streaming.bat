::脚本功能：视频转码、切分，生成HTTP Live Streaming点播视频流

::创建人：王汪
::创建时间：2013年03月27日

::修改人：王汪
::修改时间：2013年03月27日

::版本：v0.1

::脚本输入参数说明：
::参数1：待转码、切分的视频文件名，支持全路径与相对路径
::		全路径举例：E:\研究生毕业设计-基于iOS平台的流媒体播放系统的研究与实现\开发\test.avi
::		注意全路径不能包含空格
::		相对路径举例：.\test.avi、..\dir\test.avi

@ECHO OFF

::开启变量延迟
SETLOCAL ENABLEDELAYEDEXPANSION

CLS
ECHO 视频转码、切分自动化脚本（生成HTTP Live Streaming点播视频流）
ECHO 作者：王汪
::输出空行
ECHO.

IF "%1"=="" GOTO :usage
IF "%1"=="/?" GOTO :usage
IF "%1"=="help" GOTO :usage

::根据视频文件名创建转码、切分后的视频流存放根目录
SET rootpathname=%1.stream
IF EXIST "%rootpathname%" RD /S /Q "%rootpathname%"
IF NOT EXIST "%rootpathname%" MD "%rootpathname%"

::根据视频文件名获得文件名（不包含路径、后缀名）
CALL :getname "%1"
rem echo %filename%

::转码参数
::音频采样率
SET AR=44100
::音频比特率
SET AB=128000
::视频输出分辨率
SET S1=480*224
SET S2=480*224
SET S3=480*224
SET S4=640*360
SET S5=640*360
SET S6=960*540
SET S7=1280*720
SET S8=1280*720
::视频比特率
SET B1=110k
SET B2=200k
SET B3=400k
SET B4=600k
SET B5=1200k
SET B6=1800k
SET B7=2500k
SET B8=4500k
::视频横纵比
SET ASPECT=16:9
::调用外部转码程序ffmpeg
:: ffmpeg参数说明：
:: -i "%1"				输入文件
:: -f mpegts			输出格式
:: -acodec libmp3lame	音频编码器
:: -ar	音频采样率
:: -ab	音频比特率
:: -s	视频输出分辨率
:: -vcodec libx264		视频编码器
:: -b 	视频比特率
::		用-b xxxx的指令则使用固定码率，数字随便改，1500以上没效果
::		还可以用动态码率如：-qscale 4和-qscale 6，4的质量比6高
:: -flags +loop
:: -cmp +chroma
:: -partitions +parti4x4+partp8x8+partb8x8
:: -subq 5
:: -trellis 1
:: -refs 1
:: -coder 0
:: -me_range 16
:: -keyint_min 25
:: -sc_threshold 40
:: -i_qfactor 0.71		p帧、i帧qp因子
:: -bt		设置视频码率容忍度kbit/s
:: -maxrate	设置最大视频码率容忍度
:: -bufsize	设置码率控制缓冲区大小		
:: -rc_eq 'blurCplx^(1-qComp)'	设置码率控制方程 默认tex^qComp
:: -qcomp 0.6			视频量化标度压缩(VBR)
:: -qmin 10				最小视频量化标度(VBR)
:: -qmax 51				最大视频量化标度(VBR)
:: -qdiff 4				量化标度间最大偏差 (VBR)
:: -level 30
:: -aspect	视频横纵比
:: -g 30				设置图像组大小
:: -async 2
:: 命令结尾				输出文件

SET /A i=1
:loopbody
::!%I%!多次引用变量
SET resolution=!S%i%!
SET bitrate=!B%i%!
::创建视频流存放子目录
SET childpathname=%rootpathname%\%filename%_%bitrate%
IF EXIST "%childpathname%" RD /S /Q "%childpathname%"
IF NOT EXIST "%childpathname%" MD "%childpathname%"
SET outputfile=%childpathname%\%filename%_%bitrate%_pre.ts
::转码
ffmpeg -i "%1" -f mpegts -acodec libmp3lame -ar %AR% -ab %AB% -s %resolution% -vcodec libx264 -b %bitrate% -flags +loop -cmp +chroma -partitions +parti4x4+partp8x8+partb8x8 -subq 5 -trellis 1 -refs 1 -coder 0 -me_range 16 -keyint_min 25 -sc_threshold 40 -i_qfactor 0.71 -bt 200k -maxrate %bitrate% -bufsize %bitrate% -rc_eq 'blurCplx^(1-qComp)' -qcomp 0.6 -qmin 10 -qmax 51 -qdiff 4 -level 30 -aspect %ASPECT% -g 30 -async 2 %outputfile%

::拷贝切分程序至视频流存放子目录
COPY segmenter.exe %childpathname%\segmenter.exe > NUL
COPY avcodec-52.dll %childpathname%\avcodec-52.dll > NUL
COPY avutil-50.dll %childpathname%\avutil-50.dll > NUL
COPY avformat-52.dll %childpathname%\avformat-52.dll > NUL
::缓存脚本工具stream.bat当前目录
SET currentpath=%CD%
::切入视频流存放子目录
CD %childpathname%
::切分
segmenter %filename%_%bitrate%_pre.ts 10 stream_%filename%_%bitrate% %filename%_%bitrate%.m3u8 ""
::删除视频流存放子目录中的切分程序
DEL segmenter.exe
DEL avcodec-52.dll
DEL avutil-50.dll
DEL avformat-52.dll
::切回脚本工具stream.bat当前目录
CD %currentpath%
::删除转码结果文件
DEL %outputfile%
::循环变量自增
SET /A i+=1
::循环次数8次
IF NOT %i%==9 GOTO :loopbody

::退出
::完成提示输出
ECHO.
ECHO 转码、切分完成，感谢您的使用！
ECHO THX 4 U！BY wwang...
GOTO :exit

:usage
ECHO 命令语法不正确
ECHO Usage:streaming.bat [video file name]

:exit
PAUSE

::根据视频文件名获得文件名（不包含路径、后缀名）
:getname
SET filename=%~n1