import os
import csv
import sys
import pandas as pd # type: ignore
import matplotlib.pyplot as plt
from lxml import etree


def get_from_html(html_path: str):
    with open(html_path, 'rb') as file:
        html_file = file.read()
        tree = etree.HTML(html_file, None)
        tds_elem = tree.xpath(
            '//table[contains(@class, "coverage")]/tfoot/tr/td')

        tds = list(map(lambda x: x.text.strip().replace(
            ',', ''), tds_elem))  # type: list[str]

    instructions_miss, instructions_total = list(
        map(int, tds[1].split(' of ')))
    branches_miss, branches_total = list(map(int, tds[3].split(' of ')))
    cxty_miss, cxty_total = int(tds[5]), int(tds[6])
    lines_miss, lines_total = int(tds[7]), int(tds[8])
    methods_miss, methods_total = int(tds[9]), int(tds[10])
    classes_miss, classes_total = int(tds[11]), int(tds[12])

    index = int(html_path.split(os.sep)[-2].split('#')[1])
    event_count = int(html_path.split(os.sep)[-2].split('#')[2])
    instructions = (instructions_total - instructions_miss) / \
        instructions_total * 100
    branches = (branches_total - branches_miss) / branches_total * 100
    cxty = (cxty_total - cxty_miss) / cxty_total * 100
    lines = (lines_total - lines_miss) / lines_total * 100
    methods = (methods_total - methods_miss) / methods_total * 100
    classes = (classes_total - classes_miss) / classes_total * 100

    return {
        'index': index,
        'event_count': event_count,
        'instructions': instructions,
        'branches': branches,
        'cxty': cxty,
        'lines': lines,
        'methods': methods,
        'classes': classes
    }


def process_dir(dir: str):
    covs = []  # type: list[dict[str, float]]
    for dirs in os.listdir(dir):
        if os.path.isdir(os.path.join(dir, dirs)):
            path = os.path.join(dir, dirs, 'index.html')
            cov = get_from_html(path)
            covs.append(cov)

    covs.sort(key=lambda x: x['index'])

    csv_file_path = os.path.join(dir, 'coverage.csv')
    with open(csv_file_path, 'w', newline='') as csv_file:
        fieldnames = ['index', 'event_count', 'instructions', 'branches',
                      'cxty', 'lines', 'methods', 'classes']
        writer = csv.DictWriter(csv_file, fieldnames=fieldnames)

        writer.writeheader()
        for cov in covs:
            writer.writerow(cov)


def draw_from_csv(csv_path: str):
    df = pd.read_csv(csv_path)

    _, ax = plt.subplots()
    df.plot(x='index', y=['instructions', 'branches',
            'cxty', 'lines', 'methods', 'classes'], ax=ax)

    plt.xlabel('Index')
    plt.ylabel('Coverage (%)')
    plt.title('Coverage Over Time')
    plt.legend(loc='upper right')

    plt.savefig(csv_path.replace('.csv', '.png'))
    
    df = pd.read_csv(csv_path)

    _, ax = plt.subplots()
    df.plot(x='event_count', y=['instructions', 'branches',
            'cxty', 'lines', 'methods', 'classes'], ax=ax)

    plt.xlabel('Event Count')
    plt.ylabel('Coverage (%)')
    plt.title('Coverage Over Event Count')
    plt.legend(loc='upper right')

    plt.savefig(csv_path.replace('.csv', '.event.png'))


def main(dir_path: str):
    process_dir(dir_path)
    csv_path = os.path.join(dir_path, 'coverage.csv')
    draw_from_csv(csv_path)
    
    
if __name__ == '__main__':
    if (len(sys.argv) < 2):
        print("Usage: python process.py <directory_path>")
        sys.exit(1)
    
    dir_path = sys.argv[1]
    main(dir_path)
