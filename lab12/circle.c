//modified by:
//date:
//purpose:
//
//cmps 2240 lab12
//Framework for simple graphics using X11.
//
//Draw a dot (pixel)
//Draw several circles
//
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>
#include <X11/Xlib.h>
#include <X11/keysym.h>
#include <X11/extensions/Xdbe.h>

//Global variables
Display *dpy;
Window win;
GC gc;
XdbeBackBuffer backBuffer;
XdbeSwapInfo swapInfo;
int xres = 640;
int yres = 480;

//Function prototypes
void initializeX11();
void cleanupX11();
void swapBuffers();
void checkResize(XEvent *e);
void clearScreen();
void setColor(int r, int g, int b);
void showMessage(int x, int y, const char *message);
void checkMouse(XEvent *e);
int checkKeys(XEvent *e);
void physics();
void render();


int main()
{
	int done = 0;
	srand((unsigned)time(NULL));
	initializeX11();
	while (!done) {
		//Handle all pending events in X11 queue...
		while (XPending(dpy)) {
			XEvent e;
			XNextEvent(dpy, &e);
			checkResize(&e);
			checkMouse(&e);
			done = checkKeys(&e);
		}
		physics();
		render();
		XdbeSwapBuffers(dpy, &swapInfo, 1);
		usleep(2000);
	}
	cleanupX11();
	return 0;
}

void setWindowTitle()
{
	XStoreName(dpy, win, "2240 lab");
}

void initializeX11()
{
	XSetWindowAttributes attributes;
	int major, minor;
	XdbeBackBufferAttributes *backAttr;
	dpy = XOpenDisplay(NULL);
    //List of events we want to handle
	attributes.event_mask = ExposureMask | StructureNotifyMask |
							PointerMotionMask | ButtonPressMask |
							ButtonReleaseMask | KeyPressMask | KeyReleaseMask;
	//Various window attributes
	attributes.backing_store = Always;
	attributes.save_under = True;
	attributes.override_redirect = False;
	attributes.background_pixel = 0x00000000;
	//Get default root window
	Window root = DefaultRootWindow(dpy);
	//Create a window
	win = XCreateWindow(dpy, root, 0, 0, xres, yres, 0,
					    CopyFromParent, InputOutput, CopyFromParent,
					    CWBackingStore | CWOverrideRedirect | CWEventMask |
						CWSaveUnder | CWBackPixel, &attributes);
	//Create gc
	gc = XCreateGC(dpy, win, 0, NULL);
	//Get DBE version
	if (!XdbeQueryExtension(dpy, &major, &minor)) {
		printf("Error: unable to fetch Xdbe Version.\n");
		XFreeGC(dpy, gc);
		XDestroyWindow(dpy, win);
		XCloseDisplay(dpy);
		exit(1);
	}
	//Get back buffer and attributes (used for swapping)
	backBuffer = XdbeAllocateBackBufferName(dpy, win, XdbeUndefined);
	backAttr = XdbeGetBackBufferAttributes(dpy, backBuffer);
    swapInfo.swap_window = backAttr->window;
    swapInfo.swap_action = XdbeUndefined;
	XFree(backAttr);
	//Map and raise window
	setWindowTitle();
	XMapWindow(dpy, win);
	XRaiseWindow(dpy, win);
}

void cleanupX11()
{
	//Deallocate back buffer
	if (!XdbeDeallocateBackBufferName(dpy, backBuffer)) {
		printf("Error: deallocating backBuffer!\n");
	}
	XFreeGC(dpy, gc);
	XDestroyWindow(dpy, win);
	XCloseDisplay(dpy);
}

void checkResize(XEvent *e)
{
	//ConfigureNotify is sent when the window is resized.
	if (e->type != ConfigureNotify) {
		return;
	}
	XConfigureEvent xce = e->xconfigure;
	xres = xce.width;
	yres = xce.height;
	setWindowTitle();
}

void clearScreen()
{
	XSetForeground(dpy, gc, 0x00000000);
	XFillRectangle(dpy, backBuffer, gc, 0, 0, xres, yres);
}

void setColor(int r, int g, int b)
{
	//to do:
	//overload this function to accept other color formats.
	//1. one 32-bit unsigned int
	//2. three unsigned chars, values from 0 to 255
	//3. three floats, values from 0.0 to 1.0 
	//4. char string, values are words such as skyblue, purple, pink, gold
	//5. one unsigned char, this represents a gray-scale color
	//6. other overloaded functions are ok
	//
	//format of color:
	//
	//   0x00rrggbb   <---- 32 bit unsigned integer
	//
	//   rr = red
	//   gg = green
	//   bb = blue
	//
	//A color value is added to the least significant byte, then shifted
	//left. This happens for red, green, blue, but blue does not have to
	//be shifted. It is already in place.
	//You can try using bitwise-and operator with color as mask.
	unsigned long cref = 0L;
	cref += r;
	cref <<= 8;
	cref += g;
	cref <<= 8;
	cref += b;
	XSetForeground(dpy, gc, cref);
}

void checkMouse(XEvent *e)
{
	static int savex = 0;
	static int savey = 0;
	//
	if (e->type == ButtonRelease) {
		return;
	}
	if (e->type == ButtonPress) {
		if (e->xbutton.button==1) { }
		if (e->xbutton.button==3) { }
	}
	if (savex != e->xbutton.x || savey != e->xbutton.y) {
		//mouse moved
		savex = e->xbutton.x;
		savey = e->xbutton.y;
	}
}

int checkKeys(XEvent *e)
{
	int key = XLookupKeysym(&e->xkey, 0);
	//a key was pressed
	switch (key) {
		case XK_a:
			break;
		case XK_Left:
		case XK_Right:
		case XK_Up:
		case XK_Down:
			break;
		case XK_Escape:
			return 1;
	}
	return 0;
}

void physics()
{
	//This is where object movements is done.
	//None right now.
}

void setPixel(int x, int y)
{
	XDrawPoint(dpy, backBuffer, gc, x, y);
}

void BresenhamCircle(int xc, int yc, int rad)
{
	int x=0,y,d;
	int xxcp,xxcm,xycp,xycm,yxcp,yxcm,yycp,yycm;
	y = rad;
	d = 3 - (rad << 1);
	while (x <= y) {
        xxcp = xc+x;
		xxcm = xc-x;
		xycp = xc+y;
		xycm = xc-y;
		yxcp = yc+x;
		yxcm = yc-x;
		yycp = yc+y;
		yycm = yc-y;
		setPixel(yycp, xxcp);
		setPixel(yycm, xxcp);
		setPixel(yycp, xxcm);
		setPixel(yycm, xxcm);
		setPixel(yxcp, xycp);
		setPixel(yxcm, xycp);
		setPixel(yxcp, xycm);
		setPixel(yxcm, xycm);
		if (d < 0)
			d += ((x << 2) + 6);
		else
			d += (((x - y--) << 2) + 10);
		++x;
	}
}

//=====================================================================
void inlineBresenhamCircle(int xc, int yc, int rad)
{
	//Copy and paste the Bresenham circle code from above, then start
	//your inline assembly work.
	//Convert some of the code in the algorithm, but not all.
	//Double lab points for converting the entire algorithm
	// into one asm() statement. Must be individual work.
	//
	//Choose a line of code that has a bit-shift operation.
	//Bonus points for converting a line that includes a += or -- operator.

	int x=0,y,d;
	int xxcp,xxcm,xycp,xycm,yxcp,yxcm,yycp,yycm;
	
    //y = rad;
    asm("mov %%rbx, %%rax;"
        :"=a"(y)
        :"b"(rad)
       );

	//d = 3 - (rad << 1);
    asm("mov $0,%%rax;"
        "shl %%rbx;"
        "sub $3, %%rbx;"
        "mov %%rbx, %%rax;"
        :"=a"(d)
        :"b"(rad)
       );

	while (x <= y) {
        //xxcp = xc+x;
		//yycp = yc+y;
		asm("add %%rax, %%rcx;"
            "add %%rbx, %%rdx;"
            :"=c"(xxcp), "=d"(yycp)
            :"c"(xc), "d"(yc), "a"(x), "b"(y)
           );
		//xxcm = xc-x;
		//yycm = yc-y;
		asm("sub %%rax, %%rcx;"
            "sub %%rbx, %%rdx;"
            :"=c"(xxcm), "=d"(yycm)
            :"c"(xc), "d"(yc), "a"(x), "b"(y)
           );
		//xycp = xc+y;
		//xycm = xc-y;
		asm("mov %%rcx, %%r9;"
            "add %%rbx, %%rcx;"
            "sub %%rbx, %%r9;"
            "mov %%r9, %%rdx;"
            :"=c"(xycp), "=d"(xycm)
            :"c"(xc), "b"(y)
           );
		//yxcp = yc+x;
		//yxcm = yc-x;
		asm("mov %%rcx, %%r9;" 
            "add %%rax, %%rcx;"
            "sub %%rax, %%r9;"
            "mov %%r9, %%rdx;"
            :"=c"(yxcp), "=d"(yxcm)
            :"c"(yc), "a"(x)
           );
	
        setPixel(yycp, xxcp);
	    setPixel(yycm, xxcp);
		setPixel(yycp, xxcm);
		setPixel(yycm, xxcm);
		setPixel(yxcp, xycp);
		setPixel(yxcm, xycp);
		setPixel(yxcp, xycm);
		setPixel(yxcm, xycm);

        if (d < 0)

			//d += ((x << 2) + 6);
            asm("shl $2,%%rbx;"
                "add $6, %%rbx;"
                "add %%rbx, %%rax;"
                :"=a"(d)
                :"a"(d), "b"(x)
               );
		else
        {
			//d += (((x - y--) << 2) + 10);
            asm("sub $1, %%rcx;"
                "mov %%rbx, %%rdx;"
                "sub %%rcx, %%rdx;"
                "shl $2, %%rdx;"
                "add $10, %%rdx;"
                "add %%rdx, %%rax;"
                :"=a"(d), "=b"(x), "=c"(y)
                :"a"(d), "b"(x), "c"(y)
               );
        }
		//++x;
        asm("add $1, %%rax;"
            :"=a"(x)
            :"a"(x)
           );
    }




}
//=====================================================================

void render()
{
	//This is where drawing on the screen is done.
	//First, clear the screen to black.
	clearScreen();
	//
	//Establish a center point for the graphics entities.
	int x=200, y=200;
	//
	//Draw a white point on the screen
	setColor(255, 255, 255);
	//
	//The following line will draw a point.
	//XDrawPoint(dpy, backBuffer, gc, 10, 10);
	//
	//Instead, call a function defined in an assembly program.
	extern void showDot(int, int);
	showDot(x, y);
	//
	//Show text in light blue at pixel location (15,15)
	setColor(160, 200, 255);
	char mess[] = "Lab12 cmps-2240";
	XDrawString(dpy, backBuffer, gc, 15, 15, mess, strlen(mess));
	//
	//Draw a large yellow circle
	setColor(255, 255, 0);
	BresenhamCircle(x, y, 160);
	BresenhamCircle(x, y, 10);
	//
	//==============================================
	//This is part of the lab assignment...
	//Draw a green circle inside the large circle.
	//Convert some of the code to inline assembly.
	//==============================================
	setColor(100, 255, 100);
	inlineBresenhamCircle(x, y, 148);
	//==============================================
}







