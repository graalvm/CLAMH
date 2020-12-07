//==============================
// Standard headers
#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>
#include <future> // C++ async call used for parallelism

#ifdef __APPLE__
#include <sys/time.h>
#else // LINUX
#include <time.h>
#endif
//==============================
// Some handy macros...
//==============================

#define really_inline __attribute__((always_inline))
typedef uint8_t pix_t; // just store the iterations mod whatever
typedef union { uint32_t val; struct { uint8_t r,g,b,a; }; } palette_t;

//==============================
// handy predeclarations so we can list functions more in a top down ordering...
//==============================

double get_seconds(); // Returns wall time since app started in seconds
// We'll compute the palette locally...
bool save_image(const char* file_name, pix_t* data, int w, int h);

//==============================
// The meat of the benchmark!
//==============================

// For this, we just use a simple 2D Mandelbrot set, NOT the 4D Juliabrot set.
// (In this case, we only compute the 2D plane passing through Zi = 0.)
// It returns the total "brots" computed, where a "brot" is approximately
// 6 multiplies, 5 adds, a control flow branch, and 2 moves.
//
really_inline int ComputeMandelPoint(double Cr, double Ci, const int max_iter)
	{
	const double two = 2.0, four = 4.0;
	double Zr = 0.0, Zi = 0.0; // initial Z
	
	for (int i = 0; i < max_iter; i++)
		{
		// 1. Compute new Z:
		double new_Zr = Zr * Zr - Zi * Zi + Cr;
		double new_Zi = two * Zr * Zi + Ci;
		
		// 2. Check for escape:
		double mag = new_Zr * new_Zr + new_Zi * new_Zi;
		if (mag >= four) return i; // current iteration

		// 3. Move to next iteration:
		Zr = new_Zr; Zi = new_Zi;
		}
	
	return max_iter; // we're appoximately in the Mandelbrot set!
	}

// This is essentially our micro benchmark.
// Returns total brots computed for entire image.
// Note that we only store iterations for coloring, so we can take the color
//   mod 256 for convenient storage.
// We won't enable spinning the image, so we'll use the x-axis for real, and
// the y-axis for imaginary increments to C.
//
long ComputeMandelImage(double UL_Cr, double UL_Ci,double Inc_Cr,double Inc_Ci,
		const int max_iter,
		pix_t* image, int w, int h, int pitch)
	{
	long tot_brots = 0;
	
	for (int y = 0; y < h; y++, UL_Ci += Inc_Ci, image += pitch) // pitch in pixels
		{
		// start line values at each line increment.
		double Cr = UL_Cr, Ci = UL_Ci;
		pix_t* pix = image;
		
		// Do a scan line:
		for (int x = 0; x < w; x++, pix ++, Cr += Inc_Cr)
			{
			int iter = ComputeMandelPoint(Cr, Ci, max_iter);
			*pix = iter & 0xff; // draw it.
			tot_brots += iter;
			}
		}
	
	return tot_brots;
	}


// Forward declaration:
// This is just a thread spawner that leverages the main compute above!
long ComputeMandelImageMT(const int NUM_THREADS,
		double UL_Cr, double UL_Ci,double Inc_Cr,double Inc_Ci,
		const int max_iter,
		pix_t* image, int w, int h, int pitch);

// Timing the benchmark, plus defining it...
//
int main(int argc, char *argv[])
	{
	const int tot_runs = 3; // best time of 3	const int max_iter = 4096;
	const int image_w = 1024, image_h = 768;
	const int max_iter = 4096;
	
	int NUM_THREADS = 8; // The parameter you'd most like to vary.
	if (argc > 1) NUM_THREADS = atoi(argv[1]);

	pix_t *image = (pix_t*) calloc(sizeof(pix_t), image_w * image_h);
	
	// Defining the image...
	double brot_w = 3.0, brot_h = 2.5; // frame Mandelbrot
	double cen_x = -0.74529, cen_y = 0; // 0.113075; // with sweep, good for maybe 112 frames...
	double inc_x = brot_w / double(image_w);
	double inc_y = -brot_h / double(image_h);
	
	double UL_x = cen_x - inc_x * image_w/2.0;
	double UL_y = cen_y - inc_y * image_h/2.0;
	
	for (int run = 0; run < tot_runs; run++)
		{
		printf("Run #%d:  Generating %d x %d mandelbrot image, max_iter = %d.\n",
					 run+1, image_w, image_h, max_iter);
		double time_sec = get_seconds();
		
		long tot_brots = (NUM_THREADS == 1) ?
				ComputeMandelImage(UL_x, UL_y, inc_x, inc_y, max_iter, image, image_w, image_h, image_w) :
				ComputeMandelImageMT(NUM_THREADS, UL_x, UL_y, inc_x, inc_y, max_iter, image, image_w, image_h, image_w);
		
		time_sec = get_seconds() - time_sec;
		
		printf("Run #%d: Computed %ld brots in %g seconds = %g brots/sec with %d threads.\n",
					 run+1, tot_brots, time_sec, double(tot_brots) / time_sec, NUM_THREADS);
		
		// Save as check:
		save_image("./Mandelbrot.ppm", image, image_w, image_h);
		}

	return 0;
	}

// This is just a thread spawner that leverages the main compute above!
// Note that we use real components for x and imaginary for y
long ComputeMandelImageMT(const int NUM_THREADS,
		double UL_Cr, double UL_Ci,double Inc_Cr,double Inc_Ci,
		const int max_iter,
		pix_t* image, int w, int h, int pitch)
	{
	long tot_brots = 0;
	std::future<long> threads[NUM_THREADS]; // use async function call
	
	// Convert the problem into one of interleaving scanlines...
	int skip_pitch = pitch * NUM_THREADS;
	double skip_Inc_Ci = Inc_Ci * NUM_THREADS;
	
	for (int tid = 0; tid < NUM_THREADS; tid++)
		{
		double skip_UL_Ci = UL_Ci + tid * Inc_Ci;
		pix_t* skip_image = image + tid * w;
		int skip_h = (h - 1 - tid) / NUM_THREADS + 1;
		
		// Do the async call:
		threads[tid] = std::async(std::launch::async, ComputeMandelImage,
								UL_Cr, skip_UL_Ci, Inc_Cr, skip_Inc_Ci, max_iter, skip_image, w, skip_h, skip_pitch);
		}
	
	// Wait for all threads to finish and sum brots:
	for (int tid = 0; tid < NUM_THREADS; tid++)
		tot_brots += threads[tid].get();
	
	return tot_brots;
	}

//##################################
//## The supporting functions...
//##################################

double get_seconds() // Returns wall time since app started in seconds
	{
	static long slBaseSec = 0;
	static bool bFirst = true;
	struct timeval tv;
	double dTime;
	
	gettimeofday(&tv, NULL);
	
	if (bFirst) { bFirst = false; slBaseSec = tv.tv_sec; }
	
	dTime = tv.tv_usec * 0.000001;
	dTime += (double) (tv.tv_sec-slBaseSec);
	
	return dTime;
	}

//##################################
//## The Graphics Stuff
//##################################

// We need a default color palette based on iteration...
// (But we only need it up to 256 colors...)
//
palette_t *CreatePalette()
	{
	palette_t* palette  = (palette_t*) calloc(sizeof(palette_t), 256);
	
	for (int i = 0; i < 255; i++)
		{
		// there are 8 pure colors, so can add 32 shades of each:
		int shade = (i & 31) * 8;
		
		int color = (i >> 5) & 7;
		color = (color + 3) & 7; // don't start gray
		if (color == 0) color = 7; // no black possible, only white.
		
		int blue = color & 1 ? 1 : 0;
		int green = color & 2 ? 1 : 0;
		int red = color & 4 ? 1 : 0;
		
		palette[i].a = 0;
		palette[i].r = shade * red;
		palette[i].b = shade * blue;
		palette[i].g = shade * green;
		}
	
	// Need a final black for actual set:
	palette[255].val = 0;

	return palette;
	}

// We'll use the world's most inefficient file format
// because it uses the least code - the P3 "Plain" PPM format!
// PPM = Portable Pixel Map
// (See http://netpbm.sourceforge.net/doc/ppm.html#plainppm for details)
//
bool save_image(const char* file_name, pix_t* data, int w, int h)
	{
	FILE* fp = fopen(file_name, "w");
	if (!fp) { printf("Error writing to file %s\n", file_name); return false; }
	
	palette_t * palette = CreatePalette(); // standard colors
	
	fprintf(fp, "P3\n"); // magic code for plain PPM format (ASCII numbers)
	fprintf(fp, "%d %d\n", w, h);
	fprintf(fp, "%d\n\n", 255); // max luminence channel value
	
	// And now, all the image pixels:
	for (long i = 0; i < w * h; i++)
		{
		int iter = data[i];
		palette_t color = palette[iter & 255];
		fprintf(fp, "%d %d %d\n", color.r, color.g, color.b);
		}
	
	printf("Wrote image to %s\n", file_name);
	fclose(fp);
	free(palette);
	return true;
	}
