def replace_constants(rearth = 6.371e+6, omega= 7.292e-05, grav = 9.81, show_file = False):
    const_file_name = "/home/jovyan/work/pySPEEDY-aqua/speedy.f90/physical_constants.f90"
    
    try:
        with open(const_file_name, "r") as f:
            content = f.read()
        content = re.sub(r"rearth = [-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?", r"rearth = {}".format(rearth, "{:.5e}"), content)
        content = re.sub(r"omega  = [-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?", r"omega  = {}".format(omega, "{:.5e}"), content)
        content = re.sub(r"grav   = [-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?", r"grav   = {}".format(grav), content)
        
        with open(const_file_name, "w") as f:
            f.write(content)

        if show_file:
            print(content)
        
        print("Parameters successfully replaced.")
        return 0  # Success
    except Exception as e:
        print("An error occurred:")
        print(f"Error: {e}")
        return 1  # Error


if __name__ == "__main__":
    replace_constants(6.371e+6, 9.7e-05, 9.81, show_file=True)

# in terminal
#!cd /home/jovyan/work/pySPEEDY-aqua/ ; make clean ; cd .. ; pip install -v -e ./pySPEEDY-aqua
