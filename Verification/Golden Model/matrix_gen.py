import numpy as np
import random

DATA_WIDTH = 8  # You can change this to your desired data width

def generate_random_matrix(rows, cols):
    return np.random.randint(-2**(DATA_WIDTH-1), 2**(DATA_WIDTH-1)-1, size=(rows, cols))

def write_matrices_to_file(file_path, matrices):
    with open(file_path, 'w') as file:
        for matrix in matrices:
            for row in matrix:
                file.write(' '.join(map(str, row)) + '\n')
            file.write('\n')

def write_matrices_to_file_no_spaces(file_path, matrices):
    with open(file_path, 'w') as file:
        for matrix in matrices:
            for row in matrix:
                file.write(' '.join(map(str, row)) + '\n')
            #file.write('\n')


def write_dimensions_to_file(file_path, dimensions):
    with open(file_path, 'w') as file:
        for n_dim, k_dim, m_dim in dimensions:
            file.write(f"n_dim={n_dim},k_dim={k_dim},m_dim={m_dim}\n")

def transpose_matrices(input_file, output_file):
    with open(input_file, 'r') as f:
        # Read the content of the file
        content = f.read().strip()

    # Split the content into matrices based on empty lines
    matrices_str = content.split('\n\n')

    # Process each matrix
    transposed_matrices = []
    for matrix_str in matrices_str:
        # Parse matrix elements and convert them to integers
        matrix = np.array([list(map(int, row.split())) for row in matrix_str.split('\n')])
        # Transpose the matrix
        transposed_matrix = matrix.T
        transposed_matrices.append(transposed_matrix)

    # Write transposed matrices to the output file
    with open(output_file, 'w') as f:
        for matrix in transposed_matrices:
            # Write each transposed matrix to the file
            for row in matrix:
                f.write(' '.join(map(str, row)) + '\n')
            #f.write('\n')  # Separate matrices with an empty line

def main():
    num_matrices = 100000
    # For MAX_DIM=4
    matrices1 = [generate_random_matrix(rows, random.choice([2, 3, 4])) for rows in random.choices(range(2, 5), k=num_matrices)]
    matrices2 = [generate_random_matrix(cols, random.choice([2, 3, 4])) for cols in
                 [matrix.shape[1] for matrix in matrices1]]

    # For MAX_DIM=3 uncomment
    #matrices1 = [generate_random_matrix(rows, random.choice([2, 3])) for rows in random.choices(range(2, 4), k=num_matrices)]
    #matrices2 = [generate_random_matrix(cols, random.choice([2, 3])) for cols in
                    #[matrix.shape[1] for matrix in matrices1]]

    # For MAX_DIM=2 uncomment
    #matrices1 = [generate_random_matrix(rows, 2) for rows in random.choices(range(2, 3), k=num_matrices)]
    #matrices2 = [generate_random_matrix(cols, 2) for cols in
    #             [matrix.shape[1] for matrix in matrices1]]


    dimensions = [(matrix1.shape[0], matrix1.shape[1], matrix2.shape[1]) for matrix1, matrix2 in zip(matrices1, matrices2)]



    # Write matrices to files
    write_matrices_to_file('C:/logic design/Golden/matrix1.txt', matrices1) # this generates the a matrices for the golden_model.py
    write_matrices_to_file('C:/logic design/Golden/matrix2.txt', matrices2) # this generates the b matrices for the golden_model.py
    write_matrices_to_file_no_spaces('C:/logic design/Golden/matrixa.txt', matrices1) # this generates the a matrices for the design

    transpose_matrices('C:/logic design/Golden/matrix2.txt', 'C:/logic design/Golden/matrixb.txt') # this generates the b matrices for the design
    # Write dimensions to a separate file
    write_dimensions_to_file('C:/logic design/Golden/dimensions.txt', dimensions) # this generates the dimensions of both a and b for the design

if __name__ == "__main__":
    main()
