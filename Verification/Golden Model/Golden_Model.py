import numpy as np

def read_matrices(file_path):
    with open(file_path, 'r') as file:
        lines = file.readlines()
        matrices = []
        current_matrix = []
        for line in lines:
            if line.strip():  # Non-empty line
                current_matrix.append(list(map(int, line.split())))
            else:  # Empty line, indicating the end of the current matrix
                matrices.append(np.array(current_matrix, dtype=np.int64))
                current_matrix = []
        if current_matrix:  # Check if there's a matrix at the end of the file
            matrices.append(np.array(current_matrix, dtype=np.int64))
    return matrices

def write_matrix(file_path, result_matrices):
    with open(file_path, 'w') as file:
        for result_matrix in result_matrices:
            for row in result_matrix:
                file.write(' '.join(map(str, row)) + '\n')
            file.write('\n')

def write_matrix_no_spaces(file_path, result_matrices):
    with open(file_path, 'w') as file:
        for result_matrix in result_matrices:
            for row in result_matrix:
                file.write(' '.join(map(str, row)) + '\n')
            #file.write('\n')

def multiply_matrices(matrix_pairs):
    result_matrices = []
    for matrix1, matrix2 in matrix_pairs:
        result_matrices.append(np.dot(matrix1,matrix2))
    return result_matrices

def main():
    # Replace 'matrix1.txt' and 'matrix2.txt' with your actual file paths
    matrix1_path = 'C:/logic design/Golden/matrix1.txt' #matrices from matrix_gen for the calculation
    matrix2_path = 'C:/logic design/Golden/matrix2.txt' #matrices from matrix_gen for the calculation
    output_path = 'C:/logic design/Golden/result_matrix.txt' #matrices seperated by lines, easy to read, not suitable for the design
    output_pathc = 'C:/logic design/Golden/matrixc.txt' # matrices ready for the design (no line spaces)

    # Read matrices from files
    matrices1 = read_matrices(matrix1_path)
    matrices2 = read_matrices(matrix2_path)

    # Multiply matrices and get result matrices
    result_matrices = multiply_matrices(zip(matrices1, matrices2))

    # Write result matrices to the same output file
    write_matrix(output_path, result_matrices)
    write_matrix_no_spaces(output_pathc, result_matrices)

if __name__ == "__main__":
    main()
