package com.android.ably.pushdemo;

import android.graphics.Color;
import android.os.Handler;
import android.os.Looper;
import android.text.SpannableString;
import android.text.Spanned;
import android.text.style.ForegroundColorSpan;
import android.widget.TextView;

public class TextViewLogger implements Logger {
    private TextView textView;
    private Handler handler;
    private boolean closing = false;

    TextViewLogger(TextView textView) {
        this.textView = textView;
        this.handler = new Handler();
    }

    private int update(int color, String tag, String msg, Throwable tr) {
        if(closing) { return 0; }
        if(Looper.myLooper() == null) {
            updateIndirect(color, tag, msg, tr);
        } else {
            updateDirect(color, tag, msg, tr);
        }
        return 0;
    }

    private void updateIndirect(final int color, final String tag, final String msg, final Throwable tr) {
        handler.post(new Runnable() {
            @Override
            public void run() {
                updateDirect(color, tag, msg, tr);
            }
        });
    }

    private void updateDirect(int color, String tag, String msg, Throwable tr) {
        String compositeText = tag + ((msg == null) ? "" : ": " + msg) + '\n';
        if(tr != null) {
            compositeText += tr.getClass().getName() + ": " + tr.getLocalizedMessage() + '\n';
        }
        SpannableString text = new SpannableString(compositeText);
        text.setSpan(new ForegroundColorSpan(color), 0, text.length(), Spanned.SPAN_PARAGRAPH);
        textView.append(text);
    }

    void close() { closing = true; }

    @Override
    public int v(String tag, String msg) {
        return v(tag, msg, null);
    }

    @Override
    public int v(String tag, String msg, Throwable tr) {
        return update(Color.BLACK, tag, msg, tr);
    }

    @Override
    public int d(String tag, String msg) {
        return d(tag, msg, null);
    }

    @Override
    public int d(String tag, String msg, Throwable tr) {
        return update(Color.BLUE, tag, msg, tr);
    }

    @Override
    public int i(String tag, String msg) {
        return i(tag, msg, null);
    }

    @Override
    public int i(String tag, String msg, Throwable tr) {
        return update(Color.BLACK, tag, msg, tr);
    }

    @Override
    public int w(String tag, String msg) {
        return w(tag, msg, null);
    }

    @Override
    public int w(String tag, String msg, Throwable tr) {
        return update(Color.YELLOW, tag, msg, tr);
    }

    @Override
    public int w(String tag, Throwable tr) {
        return w(tag, null, tr);
    }

    @Override
    public int e(String tag, String msg) {
        return e(tag, msg, null);
    }

    @Override
    public int e(String tag, String msg, Throwable tr) {
        return update(Color.RED, tag, msg, tr);
    }

}
