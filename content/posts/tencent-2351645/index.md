{
  "title": "Codeforces Round 891 (Div. 3)AC代码",
  "date": "2023-08-10T00:00:00+08:00",
  "lastmod": "2026-10-12T00:00:00+08:00",
  "slug": "tencent-2351645",
  "author": "LinHuiG",
  "categories": [
    "算法练习"
  ],
  "tags": [],
  "draft": false,
  "original_date": "2023-08-10",
  "backfilled_at": "2026-10-12",
  "migration_source": "https://cloud.tencent.com/developer/article/2351645",
  "original_url": "https://blog.linhui.fun/article/72",
  "build": {
    "publishResources": false
  },
  "description": "Codeforces Round 891 (Div. 3)AC代码。旧文归档，原始发表于 2023-08-10。",
  "original_date_text": "2023-08-10",
  "original_sort_key": 20230810,
  "original_year": 2023,
  "date_precision": "day"
}

> **旧文迁移 · 补录说明**
>
> 原始发表：**2023-08-10**；本站迁移：**2026-10-12**。正文与代码按历史版本归档。
>
> [腾讯云原文](https://cloud.tencent.com/developer/article/2351645) · [原个人博客地址](https://blog.linhui.fun/article/72)

```java
import java.util.Arrays;
import java.util.Comparator;
import java.util.Scanner;

public class Main {
    public static void main(String[] args) {
        G();
    }


    static int n;
    static long S;
    static long mod = 998244353;
    static Edge[] a = new Edge[200005];
    static int[] bcj = new int[200005];
    static long[] bcjNum = new long[200005];

    private static void G() {
        Scanner in = new Scanner(System.in);
        int t = in.nextInt();
        for (int i = 0; i < 200005; i++) {
            a[i] = new Edge();
        }
        while (t-- > 0) {
            n = in.nextInt();
            S = in.nextInt();
            for (int i = 0; i < n - 1; i++) {
                a[i].u = in.nextInt() - 1;
                a[i].v = in.nextInt() - 1;
                a[i].w = in.nextInt();
                bcj[i] = i;
                bcjNum[i] = 1;
            }
            bcj[n - 1] = n - 1;
            bcjNum[n - 1] = 1;
            Arrays.sort(a, 0, n - 1, Comparator.comparingLong(o -> o.w));
            long sum = 1;
            for (int i = 0; i < n - 1; i++) {
                Edge edge = a[i];
                if (edge.w >= S) break;
                int uFather = getBcj(edge.u);
                int vFather = getBcj(edge.v);
                long uNum = bcjNum[uFather];
                long vNum = bcjNum[vFather];
                bcjNum[uFather] += bcjNum[vFather];
                bcj[vFather] = uFather;
                long temp = uNum * vNum - 1;
                temp %= (mod-1);
                sum *= quickPow(S - edge.w + 1, temp, mod);
                sum %= mod;
            }
            System.out.println(sum);
        }
    }

    private static int getBcj(int index) {
        return bcj[index] == index ? index : (bcj[index] = getBcj(bcj[index]));
    }

    private static long quickPow(long a, long n, long mod) {
        long ans = 1;
        a %= mod;
        while (n > 0) {
            if ((n & 1) > 0) {//如果n的当前末位为1
                ans *= a;  //ans乘上当前的a
                ans %= mod;
            }
            a *= a;        //a自乘
            a %= mod;
            n >>= 1;       //n往右移一位
        }
        return ans;
    }

    private static class Edge {
        int u, v, w;
    }

    private static void F() {
        Scanner in = new Scanner(System.in);
        int t = in.nextInt();
        int n, q;
        long x, y;
        long[] a = new long[200005];
        while (t-- > 0) {
            n = in.nextInt();
            for (int i = 0; i < n; i++) {
                a[i] = in.nextLong();
            }
            Arrays.sort(a, 0, n);
            q = in.nextInt();
            while (q-- > 0) {
                x = in.nextLong();
                y = in.nextLong();
                long tt = x * x - 4 * y;
                if (tt < 0) {
                    System.out.print(0);
                    System.out.print(' ');
                    continue;
                }
                long tq = sqrt(tt);
                long ai = x - tq;
                long aj = x + tq;
                ai /= 2;
                aj /= 2;
                if (ai + aj != x || ai * aj != y) {
                    System.out.print(0);
                    System.out.print(' ');
                    continue;
                }
                long aiCount = getCount(a, n, ai);
                if (aiCount == 0) {
                    System.out.print(0);
                    System.out.print(' ');
                    continue;
                }
                if (ai == aj) {
                    System.out.print(aiCount * (aiCount - 1) / 2);
                    System.out.print(' ');
                    continue;
                }
                long ajCount = getCount(a, n, aj);
                System.out.print(aiCount * ajCount);
                System.out.print(' ');

            }
            System.out.println();
        }
    }

    private static long sqrt(long n) {
        long low, high, mid, tmp;

        // 获取上下界
        if (n <= 1) {
            return n;
        }
        low = 1;
        high = Math.min(n, 3000000000L);

        // 二分法求开方
        while (low <= high) {
            mid = (low + high) / 2;
            tmp = mid * mid;
            if (tmp == n) {
                return mid;
            } else if (tmp > n) {
                high = mid - 1;
            } else {
                low = mid + 1;
            }
        }
        return 0;
    }

    private static int getCount(long[] a, int n, long num) {
        int lIndex = getLeftIndex(a, 0, n - 1, num);
        int rIndex = getRightIndex(a, 0, n - 1, num);
        return rIndex - lIndex + 1;
    }


    private static int getLeftIndex(long[] a, int from, int end, long num) {
        int l = from, r = end, mid = 0;
        while (l <= r) {
            mid = l + r;
            mid /= 2;
            if (a[mid] < num) {
                l = mid + 1;
            } else {
                r = mid - 1;
            }
        }
        return l;
    }

    private static int getRightIndex(long[] a, int from, int end, long num) {
        int l = from, r = end, mid = 0;
        while (l <= r) {
            mid = l + r;
            mid /= 2;
            if (a[mid] <= num) {
                l = mid + 1;
            } else {
                r = mid - 1;
            }
        }
        return r;
    }

    private static class Data {
        long val;
        long valSumLitterThanVal;
        int index;
        long result;
    }

    private static void E() {
        Scanner in = new Scanner(System.in);
        int t = in.nextInt();
        int n;
        Data[] a = new Data[200005];
        Data[] res = new Data[200005];
        for (int i = 0; i < a.length; i++) {
            a[i] = new Data();
            res[i] = a[i];
        }
        while (t-- > 0) {
            n = in.nextInt();
            for (int i = 0; i < n; i++) {
                res[i].val = in.nextInt();
                res[i].index = i;
                a[i] = res[i];
            }
            Arrays.sort(a, 0, n, Comparator.comparingLong(o -> o.val));
            a[0].valSumLitterThanVal = a[0].val;
            for (int i = 1; i < n; i++) {
                a[i].valSumLitterThanVal = a[i - 1].valSumLitterThanVal + a[i].val;
            }
            Data last = a[n - 1];
            Data currentPoint;
            for (int i = 0; i < n; i++) {
                currentPoint = a[i];
                currentPoint.result = (i + 1 - (n - i - 1)) * currentPoint.val
                        - currentPoint.valSumLitterThanVal
                        + last.valSumLitterThanVal
                        - currentPoint.valSumLitterThanVal
                        + n;
            }
            for (int i = 0; i < n; i++) {
                System.out.print(res[i].result);
                System.out.print(' ');
            }
            System.out.println();
        }
    }

    private static void D() {
        Scanner in = new Scanner(System.in);
        int t = in.nextInt();
        int[] a = new int[200005];
        int[] res = new int[200005];
        int resNum = 0;
        while (t-- > 0) {
            int n = in.nextInt();
            int maxD = Integer.MIN_VALUE;
            for (int i = 0; i < n; i++) {
                a[i] = in.nextInt();
            }
            for (int i = 0; i < n; i++) {
                a[i] = a[i] - in.nextInt();
                if (a[i] > maxD) {
                    maxD = a[i];
                    res[0] = i;
                    resNum = 1;
                } else if (maxD == a[i]) {
                    res[resNum++] = i;
                }
            }
            System.out.println(resNum);
            for (int i = 0; i < resNum; i++) {
                System.out.print(res[i] + 1);
                System.out.print(' ');
            }
            System.out.println();
        }
    }


    private static void C() {
        Scanner in = new Scanner(System.in);
        int t, n;
        int a[] = new int[1000005];
        t = in.nextInt();
        while (t-- > 0) {
            n = in.nextInt();
            int size = n * (n - 1) / 2;
            for (int i = 0; i < size; i++) {
                a[i] = in.nextInt();
            }
            Arrays.sort(a, 0, size);
            int max = a[size - 1];
            for (int i = 0; i < size; ) {
                System.out.print(a[i]);
                System.out.print(' ');
                i += --n;
                if (n == 0) {
                    break;
                }
            }
            System.out.println(max);
        }

    }

    private static void B() {
        Scanner in = new Scanner(System.in);
        int t;
        char[] a;
        t = in.nextInt();
        in.nextLine();
        while (t-- > 0) {
            String str = in.nextLine();
            a = str.toCharArray();

            int jw = -2;
            for (int index = a.length - 1; index >= 0; index--) {
                if (index == jw) {
                    if (++a[index] > '9') {
                        jw = index - 1;
                        continue;
                    }
                }
                char c = a[index];
                if (c >= '5') {
                    jw = index - 1;
                }
            }
            if (jw == -2) {
                System.out.println(str);
            } else if (jw == -1) {
                System.out.print(1);
                out0(a.length);
                System.out.println();
            } else {
                for (int i = 0; i <= jw; i++) {
                    System.out.print(a[i]);
                }
                out0(a.length - jw - 1);
                System.out.println();
            }
        }
    }

    private static void out0(int count) {
        while (count-- > 0) {
            System.out.print(0);
        }
    }

    private static void A() {
        Scanner in = new Scanner(System.in);
        int t, n, a;
        t = in.nextInt();
        while (t-- > 0) {
            n = in.nextInt();
            a = 0;
            while (n-- > 0) {
                a ^= in.nextInt() % 2;
            }
            System.out.println(a == 0 ? "YES" : "NO");
        }
    }
}
```
