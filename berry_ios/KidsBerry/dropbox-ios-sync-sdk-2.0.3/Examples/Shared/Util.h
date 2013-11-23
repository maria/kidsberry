/* Text alignment values, defined in a way which avoids deprecation
   warnings. */
#ifdef __IPHONE_6_0
# define DBX_ALIGN_LEFT NSTextAlignmentLeft
# define DBX_ALIGN_CENTER NSTextAlignmentCenter
# define DBX_ALIGN_RIGHT NSTextAlignmentRight
#else
# define DBX_ALIGN_LEFT UITextAlignmentLeft
# define DBX_ALIGN_CENTER UITextAlignmentCenter
# define DBX_ALIGN_RIGHT UITextAlignmentRight
#endif

void Alert(NSString *title, NSString *msg);
