#include <stdio.h>
#include <gtk/gtk.h>

// int main() {
//     printf("Hallo !! \n");
//
//     int i;
//     for(i=0; i<5; i++) {
//         printf("Zahl %d\n",i);
//     }
//     return 0;
// }


static void activate(GtkApplication *app, gpointer user_data) {
    GtkWidget *window;

    window = gtk_application_window_new(app);
    gtk_window_set_title(GTK_WINDOW(window), "My First GTK4 Window");
    gtk_window_set_default_size(GTK_WINDOW(window), 400, 300); // Changed for GTK4
    gtk_widget_show(window); // In GTK4, gtk_widget_show_all is often replaced by just gtk_widget_show for the main window.
}

int main(int argc, char **argv) {
    GtkApplication *app;
    int status;

    app = gtk_application_new("org.gtk.example.gtk4", G_APPLICATION_DEFAULT_FLAGS);
    g_signal_connect(app, "activate", G_CALLBACK(activate), NULL);
    status = g_application_run(G_APPLICATION(app), argc, argv);
    g_object_unref(app);

    return status;
}
