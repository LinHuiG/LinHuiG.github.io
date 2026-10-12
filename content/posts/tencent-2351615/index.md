{
  "title": "字符画视频 动态字符画java源代码",
  "date": "2019-08-20T00:00:00+08:00",
  "lastmod": "2026-10-12T00:00:00+08:00",
  "slug": "tencent-2351615",
  "author": "LinHuiG",
  "categories": [
    "Java实践"
  ],
  "tags": [
    "java",
    "video",
    "视频"
  ],
  "draft": false,
  "original_date": "2019-08-20",
  "backfilled_at": "2026-10-12",
  "migration_source": "https://cloud.tencent.com/developer/article/2351615",
  "original_url": "https://blog.linhui.fun/article/12",
  "build": {
    "publishResources": false
  },
  "description": "字符画视频 动态字符画java源代码。旧文归档，原始发表于 2019-08-20。"
}

> **旧文迁移 · 补录说明**
>
> 原始发表：**2019-08-20**；本站迁移：**2026-10-12**。原始日期依据腾讯云页尾记录，正文与代码按历史版本归档。
>
> [腾讯云原文](https://cloud.tencent.com/developer/article/2351615) · [原个人博客地址](https://blog.linhui.fun/article/12)

> **隐私处理：**本地用户目录已替换为示例路径。

在字符画的基础上增加了播放功能

思路很简单，javacv抽帧，逐帧生成对应字符画后保存，生成完通过swing播放。

视频样例：[https://www.bilibili.com/video/av64526993/](<https://www.bilibili.com/video/av64526993/>)

开源地址：[https://gitee.com/mofanyunxiang/zifuhua\_M](<https://gitee.com/mofanyunxiang/zifuhua_M>)

Flash.java

```java
package video;

import javax.imageio.ImageIO;
import java.awt.*;
import java.awt.image.BufferedImage;
import java.io.File;
import java.io.IOException;
import java.io.Serializable;
import java.lang.reflect.Array;
import java.util.Arrays;

public class Flash implements Serializable {
    transient BufferedImage image;
    String asciiImage;
    public Flash(BufferedImage image)
    {

        this.image=image;
        this.asciiImage=createAsciiPic(image);
    }
    public static String createAsciiPic(BufferedImage image) {
        image=compressImage(image);
        final String base = "@B%8&WM#*oahkbdpqwmZO0QLCJUYXzcvunxrjft/\\|()1{}[]?-_+~<>i!lI;:,\"^`'. ";// 字符串由复杂到简单
        String ans = "";
        int sl=0;
        for (int y = 0; y < image.getHeight(); y +=2) {
            for (int x = 0; x < image.getWidth(); x++) {
                final int pixel = image.getRGB(x, y);
                final int r = (pixel & 0xff0000) >> 16, g = (pixel & 0xff00) >> 8, b = pixel & 0xff;
                final float gray = 0.299f * r + 0.578f * g + 0.114f * b;
                int index = (int)(gray * (base.length() + 1) / 256);
                ans += index >= base.length() ? " " : String.valueOf(base.charAt(index));
            }
            ans += "\n";
        }
        return ans;
    }
    public static BufferedImage compressImage(BufferedImage srcImg){
        int h =  srcImg.getHeight();
        int w = srcImg.getWidth();
        int size=400;
        if(Math.max(h,w)<=size)
            return srcImg;
        int new_H;
        int new_W;
        if(w>h){
            new_W = size;
            new_H = size*h/w ;
        }else{
            new_H = size;
            new_W = size*w/h;
        }
        BufferedImage smallImg = new BufferedImage(new_W,new_H,srcImg.getType());
        Graphics g = smallImg.getGraphics();
        g.drawImage(srcImg,0,0,new_W,new_H,null);
        g.dispose();
        return smallImg;
    }

}
```

MyFrame.java

```java
package video;
import javax.swing.*;
import java.awt.*;
import java.awt.image.BufferedImage;
import java.util.Date;
import java.util.List;
import javafx.scene.media.AudioClip;

public class MyFrame extends JFrame implements Runnable {

    // 取得屏幕的宽度
    int pwidth = Toolkit.getDefaultToolkit().getScreenSize().width;
    // 取得屏幕的高度
    int pheight = Toolkit.getDefaultToolkit().getScreenSize().height;
    int height;
    int width;
    Video video;
    Thread t = new Thread(this);
    long st;
    int zs;
    AudioClip ac;
    public MyFrame(Video video,AudioClip ac,String filepath) {
        zs=0;
        this.video = video;
        width=1700;
        height=1000;

        this.setTitle("洛天依是我老婆~");
        // 设置窗体大小
        this.setSize(width, height);
        // 设置窗体出现位置
        this.setLocation((pwidth - width) / 2, (pheight - height) / 2);
        // 将窗体设置为大小不可改变
        this.setResizable(false);
        // 将窗体的关闭方式设置为默认关闭后程序结束
        this.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        this.setBackground(Color.BLACK);
        this.setVisible(true);
        this.ac=ac;
        st=0;
        try {
            Thread.sleep(3000);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        t.start();
        // 刷新屏幕,防止开始游戏时出现无法显示的情况.
        this.repaint();


    }

    /***
     * 使用了双缓冲技术防止屏幕闪烁
     * @param g
     */
    public void paint(Graphics g) {
        if(st<=0)
        {
            if(ac!=null)ac.play();
            st=new Date().getTime();
        }
        zs=(int)((new Date().getTime()-st)*video.rate/1000);
        if(zs>=video.ftp-5)return;
        String str=video.flashs.get(zs).asciiImage;
        BufferedImage bi = new BufferedImage(width, height,
                BufferedImage.TYPE_INT_RGB);
        Graphics g2 = bi.createGraphics();
        g2.setColor(Color.BLACK);
        g2.fillRect(0, 0, width, width);
        g2.setColor(Color.WHITE);
        int wsize= (width-60)/video.wsize+4;
        g2.setFont(new Font("宋体", Font.BOLD,wsize));
        String[] strs=str.split("\n");
        int i=0;
        for(String lstr:strs)
        {
            g2.drawString(lstr,40,90+i*wsize);
            i++;
        }
        g.drawImage(bi, 0, 0, this);
    }

    public void run() {
        // TODO Auto-generated method stub
        while (true) {
            this.repaint();
            try {
                Thread.sleep(30);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }
    }
}
```

Video.java

```java
package video;

import org.bytedeco.javacv.FFmpegFrameGrabber;
import org.bytedeco.javacv.Frame;
import org.bytedeco.javacv.Java2DFrameConverter;
import java.awt.image.BufferedImage;
import java.io.*;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import javafx.scene.media.AudioClip;

public class Video implements Serializable {
    private static final long serialVersionUID= 3960073332674427191l;
    double duration;
    double rate;
    int ftp;
    int finterval;
    int height;
    int width;
    int wsize;
    File videoFile;
    List<Flash> flashs;
    String fileSavePath="D:/save/";
    int flag;
    public Video(File file)
    {
        videoFile=file;
        flashs=new ArrayList<Flash>();
        flag=0;
        init(file.getPath());

    }
    public Video(String filepath)
    {
        try {
            ObjectInputStream ois=new ObjectInputStream(new FileInputStream(filepath));
            Video video=(Video) ois.readObject();
            this.duration=video.duration;
            this.rate=video.rate;
            this.ftp=video.ftp;
            this.finterval=video.finterval;
            this.height=video.height;
            this.width=video.width;
            this.wsize=video.wsize;
            this.videoFile=video.videoFile;
            this.flashs=video.flashs;
            this.flag=video.flag;
            if(flag<ftp)init(filepath);

        } catch (IOException e) {
            e.printStackTrace();
        } catch (ClassNotFoundException e) {
            e.printStackTrace();
        }
    }
    public void save(String filepath)
    {
        try {
            ObjectOutputStream oos=new ObjectOutputStream(new FileOutputStream(filepath+new Date().getTime()+".video"));
            oos.writeObject(this);
            oos.close();
        } catch (FileNotFoundException e) {
            // TODO Auto-generated catch block
            e.printStackTrace();
        } catch (IOException e) {
            // TODO Auto-generated catch block
            e.printStackTrace();
        }
    }
    public void init(String filepath)
    {
        Frame frame = null;
        FFmpegFrameGrabber fFmpegFrameGrabber = new FFmpegFrameGrabber(videoFile);

        try {
            fFmpegFrameGrabber.start();
            ftp = fFmpegFrameGrabber.getLengthInFrames();
            rate=fFmpegFrameGrabber.getFrameRate();
            duration=ftp / rate;
            finterval=(int)(1000 /rate +0.5);
            System.out.println("时长 " + ftp / rate / 60);
            System.out.println("开始运行视频提取帧，耗时较长");

            frame = fFmpegFrameGrabber.grabImage();

            height=FrameToBufferedImage(frame).getHeight();
            width=FrameToBufferedImage(frame).getWidth();
            wsize=Flash.compressImage(FrameToBufferedImage(frame)).getWidth();
            //ftp=40;
            while (flag < ftp) {
                //获取帧
                frame = fFmpegFrameGrabber.grabImage();
                if(flag<flashs.size())continue;
                if(flag/1000<(flag+1)/1000)this.save(filepath);
//                System.out.println(frame);
                if (frame != null) {
                    flashs.add(new Flash(FrameToBufferedImage(frame)));
                    flag++;
                }
                else
                {
                    ftp--;
                }
                System.out.println(flag+"/"+ftp);
                System.gc();
            }
            System.out.println("============运行结束============");
            fFmpegFrameGrabber.stop();
            this.save(filepath);

        } catch (IOException E) {
            E.printStackTrace();
        }
    }
    public static BufferedImage FrameToBufferedImage(Frame frame) {
        //创建BufferedImage对象
        Java2DFrameConverter converter = new Java2DFrameConverter();
        BufferedImage bufferedImage = converter.getBufferedImage(frame);
        return bufferedImage;
    }
}
```

Main.java

```java
import javafx.scene.media.AudioClip;
import video.MyFrame;
import video.Video;

import java.io.File;

public class Main {
    public static void main(String[] args) {
        String filepath;
        /**
         * 输入生成的video文件的路径或者个视频的路径
         * video是已完成渲染的视频，可立即启动
         * 其它视频需生成video文件后可启动
         */
        filepath = "C:\\Users\\demo-user\\Desktop\\a.video";

        Video video;

        if (filepath.substring(filepath.lastIndexOf(".") + 1).equals("video")) {
            video = new Video(filepath);
        } else {
            video = new Video(new File(filepath));
            video.save(filepath.substring(0, filepath.lastIndexOf(".")));
        }
        new MyFrame(video,
                new AudioClip(new File("C:\\Users\\demo-user\\Desktop\\a.mp3").toURI().toString())//该路径是播放音乐时的背景音乐的路径
                , filepath.substring(0, filepath.lastIndexOf("\\") + 1));
    }
}
//C:\Users\demo-user\Desktop\a.mp4
```
