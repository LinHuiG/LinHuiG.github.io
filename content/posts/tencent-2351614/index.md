{
  "title": "用A*算法让贪吃蛇跑满屏幕（顺手写了个贪吃蛇验证）",
  "date": "2019-09-07T00:00:00+08:00",
  "lastmod": "2026-10-12T00:00:00+08:00",
  "slug": "tencent-2351614",
  "author": "LinHuiG",
  "categories": [
    "算法练习"
  ],
  "tags": [
    "视频",
    "算法",
    "优化"
  ],
  "draft": false,
  "original_date": "2019-09-07",
  "backfilled_at": "2026-10-12",
  "migration_source": "https://cloud.tencent.com/developer/article/2351614",
  "original_url": "https://blog.linhui.fun/article/13",
  "build": {
    "publishResources": false
  },
  "description": "用A*算法让贪吃蛇跑满屏幕（顺手写了个贪吃蛇验证）。旧文归档，原始发表于 2019-09-07。",
  "original_date_text": "2019-09-07",
  "original_sort_key": 20190907,
  "original_year": 2019,
  "date_precision": "day"
}

> **旧文迁移 · 补录说明**
>
> 原始发表：**2019-09-07**；本站迁移：**2026-10-12**。正文与代码按历史版本归档。
>
> [腾讯云原文](https://cloud.tencent.com/developer/article/2351614) · [原个人博客地址](https://blog.linhui.fun/article/13)

思路很简单

如果蛇能吃到食物且吃到食物后能找到尾巴，就去吃食物（最短路）

否则就跟着尾巴走（最长路）

期间做了一点优化，比如把步子存起来就不用跑一步看一下了，最长路也不需要，只要不是最短路就行了

代码上传gitee了：[https://gitee.com/linhui\_fun/gluttonous\_snake](<https://gitee.com/linhui_fun/gluttonous_snake>)

试着跑了一下，视频在B站

核心代码

```java
public void AImove() {
        if (mnsnake == null) mnsnake = new ArrayDeque<>();
        else mnsnake.clear();

        for (int i = 0; i < height; i++) {
            for (int j = 0; j < width; j++) {
                btable[i][j] = -table[i][j];
            }
        }

        if (canGet(snake.getFirst(), food, btable, mnsnake) > 0) {
            for (int i = 0; i < height; i++) {
                for (int j = 0; j < width; j++) {
                    btable[i][j] = -table[i][j];
                }
            }
            for (Body_joint body_joint : mnsnake) {
                btable[body_joint.getX()][body_joint.getY()] = -1;
            }
            if (canGet(food, snake.getLast(), btable, null) > 0) {
                return;
            }



        }
        mnsnake.clear();
        int maxx = 0;
        for (int i = -1; i <= 1; i++) {
            for (int j = -1; j <= 1; j++) {
                if (i == j || i * j != 0 || isOut(snake.getFirst().getX() + i, snake.getFirst().getY() + j))
                    continue;
                if (table[snake.getFirst().getX() + i][snake.getFirst().getY() + j] != 0) continue;
                for (int ii = 0; ii < height; ii++) {
                    for (int jj = 0; jj < width; jj++) {
                        btable[ii][jj] = -table[ii][jj];
                    }
                }
                btable[snake.getLast().getX()][snake.getLast().getY()] = 0;
                int t = canGet(new Body_joint(snake.getFirst().getX() + i, snake.getFirst().getY() + j), snake.getLast(), btable, null);
                t+=snake.getFirst().getDis(food);
                if (maxx < t) {
                    maxx = t;
                    if (mnsnake.isEmpty())
                        mnsnake.addFirst(new Body_joint(snake.getFirst().getX(), snake.getFirst().getY()));
                    mnsnake.getFirst().setDx(i);
                    mnsnake.getFirst().setDy(j);
                }
            }
        }
        if(mnsnake.isEmpty())
        {
            mnsnake.addFirst(new Body_joint(snake.getFirst()));
            mnsnake.getFirst().setDx(snake.getLast().getX()-snake.getFirst().getX());
            mnsnake.getFirst().setDy(snake.getLast().getY()-snake.getFirst().getY());
        }
    }

    public int canGet(Body_joint qd, Body_joint zd, int[][] map, Deque<Body_joint> road) {


        map[qd.getX()][qd.getY()] = map[zd.getX()][zd.getY()] = 0;
        PriorityQueue<Body_joint> openlist = new PriorityQueue<>();
        int[][] oc = new int[height][width];
        int[][] ddx = new int[height][width];
        int[][] ddy = new int[height][width];
        for (int i = 0; i < height; i++) {
            for (int j = 0; j < width; j++) {
                ddx[i][j] = ddy[i][j] = oc[i][j] = 0;
            }
        }
        qd.setS(1 + qd.getDis(zd));
        openlist.add(qd);
        oc[qd.getX()][qd.getY()] = 1;//1是open -1是close
        map[qd.getX()][qd.getY()] = 1;
        Body_joint btemp, bbtemp = null;
        while (!openlist.isEmpty()) {
            if (map[zd.getX()][zd.getY()] != 0) break;
            btemp = openlist.poll();
            if (oc[btemp.getX()][btemp.getY()] == -1) continue;
            oc[btemp.getX()][btemp.getY()] = -1;
            for (int i = -1; i <= 1; i++) {
                for (int j = -1; j <= 1; j++) {
                    if (i == j || i * j != 0 || isOut(btemp.getX() + i, btemp.getY() + j) || oc[btemp.getX() + i][btemp.getY() + j] == -1 || map[btemp.getX() + i][btemp.getY() + j] == -1)
                    continue;//不可抵达或close
                    if (oc[btemp.getX() + i][btemp.getY() + j] == 0||map[btemp.getX() + i][btemp.getY() + j] > map[btemp.getX()][btemp.getY()] + 1) {
                        oc[btemp.getX() + i][btemp.getY() + j] = 1;
                        map[btemp.getX() + i][btemp.getY() + j] = map[btemp.getX()][btemp.getY()] + 1;
                        bbtemp = new Body_joint(btemp.getX() + i, btemp.getY() + j, i, j);
                        bbtemp.setS(map[btemp.getX() + i][btemp.getY() + j] + bbtemp.getDis(zd));
                        openlist.add(bbtemp);
                        ddx[bbtemp.getX()][bbtemp.getY()] = i;
                        ddy[bbtemp.getX()][bbtemp.getY()] = j;
                    }
                }
            }
        }
        if (map[zd.getX()][zd.getY()] == 0) return -1;
        ;
        if (road == null) return map[zd.getX()][zd.getY()];
        int tx = zd.getX(), ty = zd.getY();
        road.addFirst(new Body_joint(tx, ty));
        while (road.getFirst().getX() != qd.getX() || road.getFirst().getY() != qd.getY()) {
            bbtemp = new Body_joint(tx - ddx[tx][ty], ty - ddy[tx][ty]);

            bbtemp.setDx(ddx[road.getFirst().getX()][road.getFirst().getY()]);
            bbtemp.setDy(ddy[road.getFirst().getX()][road.getFirst().getY()]);

            road.addFirst(bbtemp);
            int tempx=tx;
            int tempy=ty;
            tx -= ddx[tempx][tempy];
            ty -= ddy[tempx][tempy];
        }
        road.pollLast();
        return road.size();
    }
```
