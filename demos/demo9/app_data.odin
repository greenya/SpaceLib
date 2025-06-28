package demo9

App_Data :: struct {
}

app_data_create :: proc () {
    app.data = new(App_Data)
}

app_data_destroy :: proc () {
    free(app.data)
    app.data = nil
}
