import os
import sys
import pandas as pd  # type: ignore
import matplotlib.pyplot as plt
from datetime import datetime


def diff_coverage(dir: str):
    dirs = os.listdir(dir)
    coverage_dirs = map(lambda d: os.path.join(
        dir, d, 'coverage'), filter(lambda d: not d.startswith('diff#') and 'coverage' in os.listdir(os.path.join(dir, d)), dirs))
    csv_files = list(map(lambda d: os.path.join(
        d, 'coverage.csv'), coverage_dirs))

    columns = ['instructions', 'branches',
               'cxty', 'lines', 'methods', 'classes']

    fig, axs = plt.subplots(2, 3, figsize=(14, 8))
    axs = axs.flatten()

    for csv_file in csv_files:
        df = pd.read_csv(csv_file)
        x = df.iloc[:, 0]

        label = csv_file.split(os.sep)[-3]

        for i, col in enumerate(columns):
            if col in df.columns:
                y = df[col]
                axs[i - 1].plot(x, y, label=label)

    for i, col in enumerate(columns):
        axs[i].set_title(col)
        axs[i].set_xlabel('Index')
        axs[i].set_ylim(0, 100)
        axs[i].legend()

    plt.tight_layout()
    fig.suptitle('Coverage Diff', fontsize=16)
    plt.subplots_adjust(top=0.9)

    now = datetime.now().strftime('%Y-%m-%dT%H.%M.%S')
    save_path = os.path.join(dir, f'diff#{now}', 'diff.png')

    os.makedirs(os.path.dirname(save_path), exist_ok=True)
    plt.savefig(save_path)

    fig, axs = plt.subplots(2, 3, figsize=(14, 8))
    axs = axs.flatten()

    for csv_file in csv_files:
        df = pd.read_csv(csv_file)
        x = df.iloc[:, 1]

        label = csv_file.split(os.sep)[-3]

        for i, col in enumerate(columns):
            if col in df.columns:
                y = df[col]
                axs[i - 1].plot(x, y, label=label)

    for i, col in enumerate(columns):
        axs[i].set_title(col)
        axs[i].set_xlabel('Event Count')
        axs[i].set_ylim(0, 100)
        axs[i].legend()

    plt.tight_layout()
    fig.suptitle('Coverage Diff (Event Count)', fontsize=16)
    plt.subplots_adjust(top=0.9)

    save_path = os.path.join(dir, f'diff#{now}', 'diff.event.png')

    os.makedirs(os.path.dirname(save_path), exist_ok=True)
    plt.savefig(save_path)


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: python diff_coverage.py <directory>")
        sys.exit(1)

    diff_coverage(sys.argv[1])
