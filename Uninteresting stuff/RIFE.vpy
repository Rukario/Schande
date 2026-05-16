import vapoursynth as vs
import fractions, functools, os, subprocess, sys, time, math
core = vs.core
synth_dir = os.path.dirname(os.path.realpath(__file__))
sys.path.append(rf'{synth_dir}\vs-mlrt')

echo_time = [time.time() + 2]
stdout = []
def echo(text):
    stdout.append(text)
    echo_time[0] = time.time() + 2

stdout_cmd = []
def echo_cmd(text):
    stdout_cmd.append(text.replace("\n", "&&echo."))

def load_plugin(name, path):
    if not hasattr(core, name):
        try:
            core.std.LoadPlugin(path)
        except Exception as e:
            echo(f'\n{e}')

def min_res(clip, max_w, max_h):
    w, h = clip.width, clip.height
    if w > max_w:
        new_width = max_w
        new_height = int(max_w*h/w) + (int(max_w*h/w)%2)
        if new_height > max_h:
            new_height = max_h
            new_width = int(max_h*w/h) + (int(max_h*w/h)%2)
        return clip.resize.Bicubic(width=new_width, height=new_height)
    else:
        return clip

def min_FPS(Hz, limit):
    FPS = fractions.Fraction(min(Hz, limit))

    text = f'Target FPS: {round(float(FPS), 2):g}'
    multi = fractions.Fraction(FPS.numerator, FPS_in * FPS.denominator)
    if multi.is_integer():
        text += ' (integer multiplier)'
    else:
        multi = fractions.Fraction(round(FPS), round(FPS_in))
        text += ' (integer multiplier)' if multi.is_integer() else ' (fractional multiplier)'
        ideal_Hz = round(float(FPS_in * round(FPS) / round(FPS_in)), 2)
        if not ideal_Hz == FPS:
            if ideal_Hz in legal_Hz:
                text += f'\nRecommend monitor Hz: {ideal_Hz:g}'
    if Hz > limit:
        text += ' pulldown'
    echo(text)
    return FPS, multi

try:
    clip = VpsFilterSource
    clip_FPS = clip.fps
    advanced_scd = True
except:
    clip = video_in
    clip_FPS = fractions.Fraction(container_fps)
    advanced_scd = False

FPS_in = 0
fps_23 = fractions.Fraction(24000, 1001)
for f in [fps_23, 24, fps_23*1.25, 30, fps_23*2, 48, fps_23*2.5, 60, fps_23*5, 120]:
    if math.isclose(clip_FPS, f, rel_tol=0.0001):
        FPS_in = fractions.Fraction(f)
        break
if FPS_in:
    clip = core.std.AssumeFPS(clip=clip, fpsnum=FPS_in.numerator, fpsden=FPS_in.denominator)
else:
    FPS_in = clip_FPS
# echo(f"Clip FPS: {FPS_in} ({float(FPS_in)})")

Hz = False
inst_cmd = []
modu_name = []
try:
    import win32api, win32con
    Hz = win32api.EnumDisplaySettings(None, win32con.ENUM_CURRENT_SETTINGS).DisplayFrequency
except Exception as e:
    echo(f"{e}")
    modu_name.append("win32api")
    inst_cmd.append("python.exe -m pip install pywin32")
    inst_cmd.append("python.exe scripts\pywin32_postinstall.py -install")
try:
    super = core.mv.Super(clip)
except Exception as e:
    Hz = False
    echo(f"{e}")
    modu_name.append("mvtools (mv)")
    inst_cmd.append("python.exe -m pip install vapoursynth-mvtools")
if inst_cmd:
    echo(f"""
For installing {", ".join(modu_name)}:
- Check opened command prompt window, copy multi-line then paste to execute
- Restart video player""")
    echo_cmd(rf"""cd /d {sys.exec_prefix}
{"\n".join(inst_cmd)}""")

false_Hz = [23, 29, 59, 99, 119, 239]
legal_Hz = [23.98, 24, 25, 29.98, 30, 50, 59.94, 60, 99.90, 119.88, 120, 239.76]
if Hz in false_Hz:
    # The command used to obtain Hz is in integer number, above numbers are good guess for the lost fractional Hz
    Hz += 1 - 0.024 * round(Hz/24, 1)

ratio = round(clip.width/clip.height, 2)
# echo(f'{ratio}:1')
if Hz and ratio in [1.33, 1.78, 1.85, 2.39, 2.4]:
    TRT = True
    # RTX 2060 is lowest GPU with Tensor cores that can run RIFE 640p120 (or 640p60 if TRT = False), raise limits for your graphics card.

    if TRT:
        FPS, multi = min_FPS(Hz, 120)
        # 1280 x 640
        clip = min_res(clip, 128*10, 128*5)
    else:
        FPS, multi = min_FPS(Hz, 60)
        # 1280 x 640
        clip = min_res(clip, 128*10, 128*5)

    # Allow scene change after nth consecutive frames of no detection
    since = [0, [0]*5, [0]*15]

    def scd(n, f):
        fout = f[0].copy()
        for i in range(1, 3):
            if f[i].props['_SceneChangeNext']:
                if not since[0] and not all(since[i]):
                    since[0] = i
            else:
                if since[0] == i:
                    if not any(since[i][:-1]):
                        # echo(f"Scene changed (level {i})")
                        fout.props['_SceneChangeNext'] = 1
                    # else:
                    #     echo(f"Swoop! (level {i})")
                    since[0] = 0
            since[i].pop(0)
            since[i].append(f[i+1].props['_SceneChangeNext'])
        return fout

    vectors = core.mv.Analyse(super, isb=True, blksize=32)
    if advanced_scd:
        clips = [clip]
        for thscd2 in [130, 95, 70]:
            s = core.mv.SCDetection(clip, vectors, thscd1=400, thscd2=thscd2)
            clips.append(s[1:] + s[-1])
        clip = clip.std.ModifyFrame(clips=clips, selector=scd)
    else:
        clip = core.mv.SCDetection(clip, vectors, thscd1=400, thscd2=130)
    

    clip_format = clip.format.id
    clip = clip.resize.Bicubic(format=vs.RGBS, matrix_in_s="470bg", range_s="limited")

    if TRT:
        load_plugin('trt', rf'{synth_dir}\vs-mlrt\vstrt.dll')
        if hasattr(core, 'trt'):
            from vsmlrt import RIFEModel, Backend, RIFE
            backend = Backend.TRT(fp16=True, num_streams=2, use_cuda_graph=True, output_format=1)
            model = RIFEModel.v4_6
            tile_size = 32

            w = (clip.width  + tile_size - 1) // tile_size * tile_size - clip.width
            h = (clip.height + tile_size - 1) // tile_size * tile_size - clip.height
            if w + h:
                clip = clip.std.AddBorders(right=w, bottom=h)
            clip = RIFE(clip=clip, multi=multi, model=model, video_player=True, backend=backend)
            if w + h:
                clip = clip.std.Crop(right=w, bottom=h)

            clip = core.std.AssumeFPS(clip=clip, fpsnum=multi * FPS_in.numerator, fpsden=FPS_in.denominator)

            def waitforframe2(n, f):
                return f[0]
            clip = clip.std.ModifyFrame(clips=[clip, clip.std.Trim(first=1)], selector=waitforframe2)
    else:
        # parameters at https://github.com/Asd-g/AviSynthPlus-RIFE/blob/main/README.md
        model = 23

        load_plugin('rife', rf'{synth_dir}\librife_windows_x86-64.dll')
        if hasattr(core, 'rife'):
            clip = core.rife.RIFE(clip, model, factor_num=round(FPS), factor_den=round(FPS_in), sc=True)
            # clip = core.std.AssumeFPS(clip=clip, fpsnum=FPS * 1000, fpsden=1000)

    clip = clip.resize.Bicubic(format=clip_format, matrix_s="709")
elif Hz:
    FPS, multi = min_FPS(Hz, 120)
    # 1920 x 1080
    clip = min_res(clip, 128*15, 128*8.4375)

    clip = core.std.AssumeFPS(clip=clip, fpsnum=FPS_in * 1000, fpsden=1000)
    bvec = core.mv.Analyse(super, isb=True, blksize=32)
    fvec = core.mv.Analyse(super, isb=False, blksize=32)
    bvec2 = core.mv.Recalculate(super, bvec)
    fvec2 = core.mv.Recalculate(super, fvec)
    clip = core.mv.BlockFPS(clip, super, bvec2, fvec2, num=FPS * 1000, den=1000, mode=0)
else:
    FPS = FPS_in

def stdout_dismiss(n, clip):
    if not Hz and stdout_cmd and n == int(FPS):
        os.system(f"""start cmd /k "echo {"&&echo.".join(stdout_cmd)}" """)
    if not Hz or time.time() < echo_time[0]:
        return clip.text.Text('\n'.join(stdout))
    else:
        stdout.clear()
        return clip
clip = clip.std.FrameEval(functools.partial(stdout_dismiss, clip=clip))
clip.set_output()